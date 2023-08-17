# frozen_string_literal: true
require "securerandom"

require_relative "async_call"
require_relative "callable"
require_relative "hook_event"
require_relative "hooks"
require_relative "message_queue"
require_relative "safety"
require_relative "transition_event"

module FiniteMachine
  # A class responsible for observing state changes
  class Observer < GenericDSL
    include Safety

    # Clean up callback queue
    #
    # @api private
    def cleanup_callback_queue
      proc do
        begin
          ObjectSpace.undefine_finalizer(@object_id)
          if callback_queue.alive?
            callback_queue.shutdown
          end
        rescue MessageQueueDeadError
        end
      end
    end

    # The current state machine
    attr_reader :machine

    # The hooks to trigger around the transition lifecycle.
    attr_reader :hooks

    # Initialize an Observer
    #
    # @param [StateMachine] machine
    #   reference to the current machine
    #
    # @api public
    def initialize(machine)
      @machine = machine
      @hooks   = Hooks.new
      @object_id = nil

      @machine.subscribe(self)
    end

    def callback_queue
      return @callback_queue if instance_variable_defined?(:@callback_queue)
      @object_id = SecureRandom.uuid
      ObjectSpace.define_finalizer(@object_id, cleanup_callback_queue)
      @callback_queue = MessageQueue.new
    end

    # Evaluate in current context
    #
    # @api private
    def call(&block)
      instance_eval(&block)
    end

    # Register callback for a given hook type
    #
    # @param [HookEvent] hook_type
    # @param [Symbol] state_or_event_name
    # @param [Proc] callback
    #
    # @example
    #   observer.on HookEvent::Enter, :green
    #
    # @api public
    def on(hook_type, state_or_event_name = nil, async = nil, &callback)
      sync_exclusive do
        if state_or_event_name.nil?
          state_or_event_name = HookEvent.any_state_or_event(hook_type)
        end
        async = false if async.nil?
        ensure_valid_callback_name!(hook_type, state_or_event_name)
        callback.extend(Async) if async == :async
        hooks.register(hook_type, state_or_event_name, callback)
      end
    end

    # Unregister callback for a given event
    #
    # @api public
    def off(hook_type, name = ANY_STATE, &callback)
      sync_exclusive do
        hooks.unregister hook_type, name, callback
      end
    end

    module Once; end

    module Async; end

    def on_enter(*args, &callback)
      on HookEvent::Enter, *args, &callback
    end

    def on_transition(*args, &callback)
      on HookEvent::Transition, *args, &callback
    end

    def on_exit(*args, &callback)
      on HookEvent::Exit, *args, &callback
    end

    def once_on_enter(*args, &callback)
      on HookEvent::Enter, *args, &callback.extend(Once)
    end

    def once_on_transition(*args, &callback)
      on HookEvent::Transition, *args, &callback.extend(Once)
    end

    def once_on_exit(*args, &callback)
      on HookEvent::Exit, *args, &callback.extend(Once)
    end

    def on_before(*args, &callback)
      on HookEvent::Before, *args, &callback
    end

    def on_after(*args, &callback)
      on HookEvent::After, *args, &callback
    end

    def once_on_before(*args, &callback)
      on HookEvent::Before, *args, &callback.extend(Once)
    end

    def once_on_after(*args, &callback)
      on HookEvent::After, *args, &callback.extend(Once)
    end

    # Execute each of the hooks in order with supplied data
    #
    # @param [HookEvent] event
    #   the hook event
    #
    # @param [Array[Object]] data
    #
    # @return [nil]
    #
    # @api public
    def emit(event, *data)
      sync_exclusive do
        [event.type].each do |hook_type|
          any_state_or_event = HookEvent.any_state_or_event(hook_type)
          [any_state_or_event, event.name].each do |event_name|
            hooks[hook_type][event_name].each do |hook|
              handle_callback(hook, event, *data)
              off(hook_type, event_name, &hook) if hook.is_a?(Once)
            end
          end
        end
      end
    end

    # Cancel the current event
    #
    # This should be called inside a on_before or on_exit callbacks
    # to prevent event transition.
    #
    # @param [String] msg
    #   the message used for failure
    #
    # @api public
    def cancel_event(msg = nil)
      raise CallbackError.new(msg)
    end

    private

    # Handle callback and decide if run synchronously or asynchronously
    #
    # @param [Proc] :hook
    #   The hook to evaluate
    #
    # @param [HookEvent] :event
    #   The event for which the hook is called
    #
    # @param [Array[Object]] :data
    #
    # @api private
    def handle_callback(hook, event, *data)
      to = machine.events_map.move_to(event.event_name, event.from, *data)
      trans_event = TransitionEvent.new(event.event_name, event.from, to)
      callable    = create_callable(hook)

      if hook.is_a?(Async)
        defer(callable, trans_event, *data)
      else
        callable.(trans_event, *data)
      end
    end

    # Defer callback execution
    #
    # @api private
    def defer(callable, trans_event, *data)
      async_call = AsyncCall.new(machine, callable, trans_event, *data)
      callback_queue.start unless callback_queue.running?
      callback_queue << async_call
    end

    # Create callable instance
    #
    # @api private
    def create_callable(hook)
      callback = proc do |trans_event, *data|
        machine.instance_exec(trans_event, *data, &hook)
      end
      Callable.new(callback)
    end

    # Callback names including all states and events
    #
    # @return [Array[Symbol]]
    #   valid callback names
    #
    # @api private
    def callback_names
      machine.states + machine.events + [ANY_EVENT, ANY_STATE]
    end

    # Forward the message to observer
    #
    # @param [String] method_name
    #
    # @param [Array] args
    #
    # @return [self]
    #
    # @api private
    def method_missing(method_name, *args, &block)
      _, event_name, callback_name = *method_name.to_s.match(/^(\w*?on_\w+?)_(\w+)$/)
      if callback_name && callback_names.include?(callback_name.to_sym)
        public_send(event_name, :"#{callback_name}", *args, &block)
      else
        super
      end
    end

    # Test if a message can be handled by observer
    #
    # @param [String] method_name
    #
    # @param [Boolean] include_private
    #
    # @return [Boolean]
    #
    # @api private
    def respond_to_missing?(method_name, include_private = false)
      *_, callback_name = *method_name.to_s.match(/^(\w*?on_\w+?)_(\w+)$/)
      callback_name && callback_names.include?(:"#{callback_name}")
    end
  end # Observer
end # FiniteMachine
