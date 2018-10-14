# frozen_string_literal: true

require 'forwardable'

require_relative 'async_proxy'
require_relative 'catchable'
require_relative 'dsl'
require_relative 'env'
require_relative 'events_chain'
require_relative 'hook_event'
require_relative 'observer'
require_relative 'threadable'
require_relative 'subscribers'

module FiniteMachine
  # Base class for state machine
  class StateMachine
    include Threadable
    include Catchable
    extend Forwardable

    # Initial state, defaults to :none
    attr_threadsafe :initial_state

    # Final state, defaults to :none
    attr_threadsafe :final_state

    # The prefix used to name events.
    attr_threadsafe :namespace

    # The state machine environment
    attr_threadsafe :env

    # The state machine event definitions
    attr_threadsafe :events_chain

    # Errors DSL
    #
    # @return [ErrorsDSL]
    #
    # @api private
    attr_threadsafe :errors_dsl

    # Events DSL
    #
    # @return [EventsDSL]
    #
    # @api private
    attr_threadsafe :events_dsl

    # The state machine observer
    #
    # @return [Observer]
    #
    # @api private
    attr_threadsafe :observer

    # Current state
    #
    # @return [Symbol]
    #
    # @api private
    attr_threadsafe :state

    # The state machine subscribers
    #
    # @return [Subscribers]
    #
    # @api private
    attr_threadsafe :subscribers

    # Allow or not logging of transitions
    attr_threadsafe :log_transitions

    def_delegators :@dsl, :initial, :terminal, :target, :trigger_init,
                   :alias_target

    def_delegator :events_dsl, :event

    def_delegator :@async_proxy, :event_queue

    # Initialize state machine
    #
    # @api private
    def initialize(*args, &block)
      attributes     = args.last.is_a?(Hash) ? args.pop : {}

      @initial_state = DEFAULT_STATE
      @async_proxy   = AsyncProxy.new(self)
      @subscribers   = Subscribers.new
      @observer      = Observer.new(self)
      @events_chain  = EventsChain.new
      @env           = Env.new(self, [])
      @events_dsl    = EventsDSL.new(self)
      @errors_dsl    = ErrorsDSL.new(self)
      @dsl           = DSL.new(self, attributes)

      @dsl.call(&block) if block_given?
      trigger_init
    end

    # Subscribe observer for event notifications
    #
    # @example
    #   machine.subscribe(Observer.new(machine))
    #
    # @api public
    def subscribe(*observers)
      sync_exclusive { subscribers.subscribe(*observers) }
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
      if method_name
        @async_proxy.method_missing(method_name, *args, &block)
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
      sync_shared { events_chain.states }
    end

    # Retireve all event names
    #
    # @example
    #   fsm.event_names # => [:init, :start, :stop]
    #
    # @return [Array[Symbol]]
    #
    # @api public
    def event_names
      sync_shared { events_chain.events }
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
    def can?(*args)
      event_name  = args.shift
      events_chain.can_perform?(event_name, current, *args)
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

    # Check if state is reachable
    #
    # @param [Symbol] event_name
    #   the event name for all transitions
    #
    # @return [Boolean]
    #
    # @api private
    def valid_state?(event_name)
      current_states = events_chain.states_for(event_name)
      current_states.any? { |state| state == current || state == ANY_STATE }
    end

    # Notify about event all the subscribers
    #
    # @param [HookEvent] :hook_event_type
    #   The hook event type.
    # @param [FiniteMachine::Transition] :event_transition
    #   The event transition.
    # @param [Array[Object]] :data
    #   The data associated with the hook event.
    #
    # @return [nil]
    #
    # @api private
    def notify(hook_event_type, event_name, from, *data)
      sync_shared do
        hook_event = hook_event_type.build(current, event_name, from)
        subscribers.visit(hook_event, *data)
      end
    end

    # Attempt performing event trigger for valid state
    #
    # @return [Boolean]
    #   true is trigger successful, false otherwise
    #
    # @api private
    def try_trigger(event_name)
      if valid_state?(event_name)
        yield
      else
        exception = InvalidStateError
        catch_error(exception) ||
          fail(exception, "inappropriate current state '#{current}'")

        false
      end
    end

    # Trigger transition event with data
    #
    # @param [Symbol] event_name
    #   the event name
    # @param [Array] data
    #
    # @return [Boolean]
    #   true when transition is successful, false otherwise
    #
    # @api public
    def trigger!(event_name, *data, &block)
      sync_exclusive do
        from = current # Save away current state

        notify HookEvent::Before, event_name, from, *data

        status = try_trigger(event_name) do
          if can?(event_name, *data)
            notify HookEvent::Exit, event_name, from, *data

            stat = transition!(event_name, *data, &block)

            notify HookEvent::Transition, event_name, from, *data
            notify HookEvent::Enter, event_name, from, *data
          else
            stat = false
          end
          stat
        end

        notify HookEvent::After, event_name, from, *data

        status
      end
    end

    # Trigger transition event without raising any errors
    #
    # @param [Symbol] event_name
    #
    # @return [Boolean]
    #   true on successful transition, false otherwise
    #
    # @api public
    def trigger(event_name, *data, &block)
      trigger!(event_name, *data, &block)
    rescue InvalidStateError, TransitionError
      false
    end

    # Find available state to transition to and transition
    #
    # @param [Symbol] event_name
    #
    # @api private
    def transition!(event_name, *data, &block)
      from_state = current
      to_state   = events_chain.move_to(event_name, from_state, *data)

      block.call(from_state, to_state) if block

      if log_transitions
        Logger.report_transition(event_name, from_state, to_state, *data)
      end

      try_trigger(event_name) { transition_to!(to_state) }
    end

    def transition(event_name, *data, &block)
      transition!(event_name, *data, &block)
    rescue InvalidStateError, TransitionError
      false
    end

    # Update this state machine state to new one
    #
    # @param [Symbol] new_state
    #
    # @raise [TransitionError]
    #
    # @api private
    def transition_to!(new_state)
      from_state = current
      self.state = new_state
      self.initial_state = new_state if from_state == DEFAULT_STATE
      true
    rescue Exception => e
      catch_error(e) || raise_transition_error(e)
    end

    # String representation of this machine
    #
    # @return [String]
    #
    # @api public
    def inspect
      sync_shared do
        "<##{self.class}:0x#{object_id.to_s(16)} @states=#{states}, " \
        "@events=#{event_names}, " \
        "@transitions=#{events_chain.state_transitions}>"
      end
    end

    private

    # Raise when failed to transition between states
    #
    # @param [Exception] error
    #   the error to describe
    #
    # @raise [TransitionError]
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
