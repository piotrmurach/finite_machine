# encoding: utf-8

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

    # The previous state before transition
    attr_threadsafe :previous_state

    # The state machine event definitions
    attr_threadsafe :events_chain

    # Allow or not logging of transitions
    attr_threadsafe :log_transitions

    def_delegators :@dsl, :initial, :terminal, :target, :trigger_init,
                   :alias_target

    def_delegator :@events_dsl, :event

    def_delegators :@events_chain, :check_choice_conditions, :select_transition,
                   :select_choice_transition

    # Initialize state machine
    #
    # @api private
    def initialize(*args, &block)
      attributes     = args.last.is_a?(Hash) ? args.pop : {}
      @initial_state = DEFAULT_STATE
      @subscribers   = Subscribers.new(self)
      @observer      = Observer.new(self)
      @transitions   = Transitions.new
      @events_chain  = EventsChain.new(self)
      @env           = Env.new(self, [])
      @events_dsl    = EventsDSL.new(self)
      @errors        = ErrorsDSL.new(self)
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
    # Notify about event all the subscribers
    #
    # @param [FiniteMachine::HookEvent] :event_type
    #   The hook event type.
    # @param [FiniteMachine::Transition] :event_transition
    #   The event transition.
    # @param [Array[Object]] :data
    #   The data associated with the hook event.
    #
    # @return [nil]
    #
    # @api public
    def notify(event_type, event_transition, *data)
      sync_shared do
        hook_event = event_type.build(state, event_transition, *data)
        subscribers.visit(hook_event)
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
      valid_state && events_chain.valid_event?(event, *args, &block)
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
    def terminated?
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
    # @param [FiniteMachine::Transition]
    #
    # @return [Boolean]
    #
    # @api private
    def valid_state?(event_transition)
      current_states = transitions[event_transition.name].keys
      if !current_states.include?(state) && !current_states.include?(ANY_STATE)
        exception = InvalidStateError
        catch_error(exception) ||
          fail(exception, "inappropriate current state '#{state}'")
        return false
      end
      return true
    end

    # Performs transition
    #
    # @param [Transition] event_transition
    # @param [Array] args
    #
    # @return [Integer]
    #   the status code for the transition
    #
    # @api private
    def transition(event_transition, *args, &block)
      sync_exclusive do
        notify HookEvent::Before, event_transition, *args

        if valid_state?(event_transition) && event_transition.valid?(*args, &block)
          notify HookEvent::Exit, event_transition, *args

          begin
            event_transition.execute(*args)
            Logger.report_transition(event_transition, *args) if log_transitions

            notify HookEvent::Transition, event_transition, *args
          rescue Exception => e
            catch_error(e) || raise_transition_error(e)
          end

          notify HookEvent::Enter, event_transition, *args

          notify HookEvent::After, event_transition, *args

          event_transition.same?(state) ? NOTRANSITION : SUCCEEDED
        else
          notify HookEvent::After, event_transition, *args

          CANCELLED
        end
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
      fail TransitionError, Logger.format_error(error)
    end

    # Forward the message to observer or self
    #
    # @param [String] method_name
    #
    # @param [Array] args
    #
    # @return [self]
    #
    # @api private
    def method_missing(method_name, *args, &block)
      if observer.respond_to?(method_name.to_sym)
        observer.public_send(method_name.to_sym, *args, &block)
      elsif env.aliases.include?(method_name.to_sym)
        env.send(:target, *args, &block)
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
      observer.respond_to?(method_name.to_sym) ||
        env.aliases.include?(method_name.to_sym) || super
    end
  end # StateMachine
end # FiniteMachine
