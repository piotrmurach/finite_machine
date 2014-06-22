# encoding: utf-8

require 'forwardable'

module FiniteMachine
  # Base class for state machine
  class StateMachine
    include Threadable
    include Catchable
    include ThreadContext
    extend Forwardable

    # Initial state, defaults to :none
    attr_threadsafe :initial_state

    # Final state, defaults to :none
    attr_threadsafe :final_state

    # Current state
    attr_threadsafe :state

    # Events DSL
    attr_threadsafe :events_dsl

    # Errors DSL
    attr_threadsafe :errors

    # The prefix used to name events.
    attr_threadsafe :namespace

    # The events and their transitions.
    attr_threadsafe :transitions

    # The state machine observer
    attr_threadsafe :observer

    # The state machine subscribers
    attr_threadsafe :subscribers

    # The state machine environment
    attr_threadsafe :env

    # The state machine event definitions
    attr_threadsafe :events_chain

    def_delegators :@dsl, :initial, :terminal, :target, :trigger_init

    def_delegator :@events_dsl, :event

    # Initialize state machine
    #
    # @api private
    def initialize(*args, &block)
      attributes     = args.last.is_a?(Hash) ? args.pop : {}
      @initial_state = DEFAULT_STATE
      @subscribers   = Subscribers.new(self)
      @events_dsl    = EventsDSL.new(self)
      @errors        = ErrorsDSL.new(self)
      @observer      = Observer.new(self)
      @transitions   = Hash.new { |hash, name| hash[name] = Hash.new }
      @events_chain  = {}
      @env           = Environment.new(target: self)
      @dsl           = DSL.new(self, attributes)

      @dsl.call(&block) if block_given?
      trigger_init
    end

    # @example
    #   machine.subscribe(Observer.new(machine))
    #
    # @api public
    def subscribe(*observers)
      @subscribers.subscribe(*observers)
    end

    # TODO:  use trigger to actually fire state machine events!
    # Notify about event
    #
    # @api public
    def notify(event_type, _transition, *data)
      sync_shared do
        state_or_action = event_type < HookEvent::Anystate ? state : _transition.name
        _event          = event_type.new(state_or_action, _transition, *data)
        subscribers.visit(_event)
      end
    end

    # Help to mark the event as synchronous
    #
    # @example
    #   fsm.sync.go
    #
    # @return [self]
    #
    # @api public
    alias_method :sync, :method_missing

    # Explicitly invoke event on proxy or delegate to proxy
    #
    # @return [AsyncProxy]
    #
    # @api public
    def async(method_name = nil, *args, &block)
      @async_proxy = AsyncProxy.new(self)
      if method_name
        @async_proxy.method_missing method_name, *args, &block
      else
        @async_proxy
      end
    end

    # Get current state
    #
    # @return [String]
    #
    # @api public
    def current
      state
    end

    # Check if current state matches provided state
    #
    # @example
    #   fsm.is?(:green) # => true
    #
    # @param [String, Array[String]] state
    #
    # @return [Boolean]
    #
    # @api public
    def is?(state)
      if state.is_a?(Array)
        state.include? current
      else
        state == current
      end
    end

    # Retrieve all states
    #
    # @example
    #  fsm.states # => [:yellow, :green, :red]
    #
    # @return [Array[Symbol]]
    #
    # @api public
    def states
      sync_shared do
        event_names.map { |event| transitions[event].to_a }.flatten.uniq
      end
    end

    # Retireve all event names
    #
    # @return [Array[Symbol]]
    #
    # @api public
    def event_names
      sync_shared { transitions.keys }
    end

    # Checks if event can be triggered
    #
    # @example
    #   fsm.can?(:go) # => true
    #
    # @example
    #   fsm.can?(:go, 'Piotr')  # checks condition with parameter 'Piotr'
    #
    # @param [String] event
    #
    # @return [Boolean]
    #
    # @api public
    def can?(*args, &block)
      event       = args.shift
      valid_state = transitions[event].key?(current)
      valid_state ||= transitions[event].key?(ANY_STATE)
      valid_state &&= events_chain[event].next_transition.valid?(*args, &block)
    end

    # Checks if event cannot be triggered
    #
    # @example
    #   fsm.cannot?(:go) # => false
    #
    # @param [String] event
    #
    # @return [Boolean]
    #
    # @api public
    def cannot?(*args, &block)
      !can?(*args, &block)
    end

    # Checks if terminal state has been reached
    #
    # @return [Boolean]
    #
    # @api public
    def finished?
      is?(final_state)
    end

    # Restore this machine to a known state
    #
    # @param [Symbol] state
    #
    # @return nil
    #
    # @api public
    def restore!(state)
      sync_exclusive { self.state = state }
    end

    # String representation of this machine
    #
    # @return [String]
    #
    # @api public
    def inspect
      sync_shared do
        "<##{self.class}:0x#{object_id.to_s(16)} @states=#{states}, " \
        "@events=#{event_names}, @transitions=#{transitions.inspect}>"
      end
    end

    private

    # Check if state is reachable
    #
    # @api private
    def valid_state?(_transition)
      current_states = transitions[_transition.name].keys
      if !current_states.include?(state) && !current_states.include?(ANY_STATE)
        exception = InvalidStateError
        catch_error(exception) ||
          raise(exception, "inappropriate current state '#{state}'")
        true
      end
    end

    # Performs transition
    #
    # @param [Transition] _transition
    # @param [Array] args
    #
    # @return [Integer]
    #   the status code for the transition
    #
    # @api private
    def transition(_transition, *args, &block)
      sync_exclusive do
        notify HookEvent::Before, _transition, *args

        return CANCELLED if valid_state?(_transition)
        return CANCELLED unless _transition.valid?(*args, &block)

        notify HookEvent::Exit, _transition, *args

        begin
          _transition.call

          notify HookEvent::Transition, _transition, *args
        rescue Exception => e
          catch_error(e) || raise_transition_error(e)
        end

        notify HookEvent::Enter, _transition, *args
        notify HookEvent::After, _transition, *args

        _transition.same?(state) ? NOTRANSITION : SUCCEEDED
      end
    end

    # Raise when failed to transition between states
    #
    # @param [Exception] error
    #   the error to describe
    #
    # @raise [FiniteMachine::TransitionError]
    #
    # @api private
    def raise_transition_error(error)
      fail(TransitionError, "#(#{error.class}): #{error.message}\n" \
        "occured at #{error.backtrace.join("\n")}")
    end

    # Forward the message to target, observer or self
    #
    # @param [String] method_name
    #
    # @param [Array] args
    #
    # @return [self]
    #
    # @api private
    def method_missing(method_name, *args, &block)
      if target.respond_to?(method_name.to_sym)
        target.public_send(method_name.to_sym, *args, &block)
      elsif observer.respond_to?(method_name.to_sym)
        observer.public_send(method_name.to_sym, *args, &block)
      else
        super
      end
    end

    # Test if a message can be handled by state machine
    #
    # @param [String] method_name
    #
    # @param [Boolean] include_private
    #
    # @return [Boolean]
    #
    # @api private
    def respond_to_missing?(method_name, include_private = false)
      env.target.respond_to?(method_name.to_sym) ||
        observer.respond_to?(method_name.to_sym) ||
        super
    end
  end # StateMachine
end # FiniteMachine
