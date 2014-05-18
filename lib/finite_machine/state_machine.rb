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

    def_delegators :@dsl, :initial, :terminal, :target

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
        event_class     = HookEvent.const_get(event_type.capitalize.to_s)
        state_or_action = event_class < HookEvent::Anystate ? state : _transition.name
        _event          = event_class.new(state_or_action, _transition, *data)
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
      event_names.map { |event| transitions[event].to_a }.flatten.uniq
    end

    # Retireve all event names
    #
    # @return [Array[Symbol]]
    #
    # @api public
    def event_names
      transitions.keys
    end

    # Checks if event can be triggered
    #
    # @example
    #   fsm.can?(:go) # => true
    #
    # @param [String] event
    #
    # @return [Boolean]
    #
    # @api public
    def can?(event)
      transitions[event].key?(current) || transitions[event].key?(ANY_STATE)
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
    def cannot?(event)
      !can?(event)
    end

    # Checks if terminal state has been reached
    #
    # @return [Boolean]
    #
    # @api public
    def finished?
      is?(final_state)
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
      return CANCELLED if valid_state?(_transition)

      return CANCELLED unless _transition.conditions.all? do |condition|
                                condition.call(env.target, *args)
                              end
      return NOTRANSITION if _transition.different?(state)

      sync_exclusive do
        notify :exitstate, _transition, *args

        begin
          _transition.call
          notify :enteraction, _transition, *args
          notify :transitionstate, _transition, *args
          notify :transitionaction, _transition, *args
        rescue Exception => e
          catch_error(e) ||
            raise(TransitionError, "#(#{e.class}): #{e.message}\n" +
              "occured at #{e.backtrace.join("\n")}")
        end

        notify :enterstate, _transition, *args
        notify :exitaction, _transition, *args
      end

      SUCCEEDED
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
      if env.target.respond_to?(method_name.to_sym)
        env.target.public_send(method_name.to_sym, *args, &block)
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
      env.target.respond_to?(method_name.to_sym)
    end
  end # StateMachine
end # FiniteMachine
