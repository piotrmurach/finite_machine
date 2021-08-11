# frozen_string_literal: true

require "forwardable"
require "securerandom"

require_relative "catchable"
require_relative "dsl"
require_relative "env"
require_relative "events_map"
require_relative "hook_event"
require_relative "observer"
require_relative "threadable"
require_relative "subscribers"

module FiniteMachine
  # Base class for state machine
  class StateMachine
    include Threadable
    include Catchable
    extend Forwardable

    # Current state
    #
    # @return [Symbol]
    #
    # @api private
    attr_threadsafe :state

    # Initial state, defaults to :none
    attr_threadsafe :initial_state

    # Final state, defaults to nil
    attr_threadsafe :terminal_states

    # The prefix used to name events.
    attr_threadsafe :namespace

    # The state machine environment
    attr_threadsafe :env

    # The state machine event definitions
    attr_threadsafe :events_map

    # Machine dsl
    #
    # @return [DSL]
    #
    # @api private
    attr_threadsafe :dsl

    # The state machine observer
    #
    # @return [Observer]
    #
    # @api private
    attr_threadsafe :observer

    # The state machine subscribers
    #
    # @return [Subscribers]
    #
    # @api private
    attr_threadsafe :subscribers

    # Allow or not logging of transitions
    attr_threadsafe :log_transitions

    def_delegators :dsl, :initial, :terminal, :event, :trigger_init,
                   :alias_target

    # Initialize state machine
    #
    # @example
    #   fsm = FiniteMachine::StateMachine.new(target_alias: :car) do
    #     initial :red
    #
    #     event :go, :red => :green
    #
    #     on_transition do |event|
    #       car.state = event.to
    #     end
    #   end
    #
    # @param [Hash] options
    #   the options to create state machine with
    # @option options [String] :alias_target
    #   the alias for target object
    #
    # @api private
    def initialize(*args, &block)
      options = args.last.is_a?(::Hash) ? args.pop : {}
      @initial_state = DEFAULT_STATE
      @auto_methods  = options.fetch(:auto_methods, true)
      @subscribers   = Subscribers.new
      @observer      = Observer.new(self)
      @events_map    = EventsMap.new
      @env           = Env.new(self, [])
      @dsl           = DSL.new(self, options)
      @name          = options.fetch(:name) { SecureRandom.uuid.split("-")[0] }

      env.target = args.pop unless args.empty?
      env.aliases << options[:alias_target] if options[:alias_target]
      dsl.call(&block) if block_given?
      trigger_init
    end

    # Check if event methods should be auto generated
    #
    # @return [Boolean]
    #
    # @api public
    def auto_methods?
      @auto_methods
    end

    # Attach state machine to an object
    #
    # This allows state machine to initiate events in the context
    # of a particular object
    #
    # @example
    #   FiniteMachine.define(target: object) do
    #     ...
    #   end
    #
    # @return [Object|FiniteMachine::StateMachine]
    #
    # @api public
    def target
      env.target
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

    # Get current state
    #
    # @return [String]
    #
    # @api public
    def current
      sync_shared { state }
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
      sync_shared { events_map.states }
    end

    # Retireve all event names
    #
    # @example
    #   fsm.events # => [:init, :start, :stop]
    #
    # @return [Array[Symbol]]
    #
    # @api public
    def events
      events_map.events
    end

    # Checks if event can be triggered
    #
    # @example
    #   fsm.can?(:go) # => true
    #
    # @example
    #   fsm.can?(:go, "Piotr")  # checks condition with parameter "Piotr"
    #
    # @param [String] event
    #
    # @return [Boolean]
    #
    # @api public
    def can?(*args)
      event_name = args.shift
      events_map.can_perform?(event_name, current, *args)
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
      is?(terminal_states)
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
      current_states = events_map.states_for(event_name)
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
          raise(exception, "inappropriate current state '#{current}'")

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
      from = current # Save away current state

      sync_exclusive do
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
    rescue Exception => err
      self.state = from # rollback transition
      raise err
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
    rescue InvalidStateError, TransitionError, CallbackError
      false
    end

    # Find available state to transition to and transition
    #
    # @param [Symbol] event_name
    #
    # @api private
    def transition!(event_name, *data, &block)
      from_state = current
      to_state   = events_map.move_to(event_name, from_state, *data)

      block.call(from_state, to_state) if block

      if log_transitions
        Logger.report_transition(@name, event_name, from_state, to_state, *data)
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
        "<##{self.class}:0x#{object_id.to_s(16)} " \
        "@current=#{current.inspect} " \
        "@states=#{states} " \
        "@events=#{events} " \
        "@transitions=#{events_map.state_transitions}>"
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
      raise TransitionError, Logger.format_error(error)
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
