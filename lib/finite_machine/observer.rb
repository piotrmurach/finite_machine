# encoding: utf-8

require 'set'

module FiniteMachine
  # A class responsible for observing state changes
  class Observer
    include Threadable
    include Safety

    # The current state machine
    attr_threadsafe :machine

    # The hooks to trigger around the transition lifecycle.
    attr_threadsafe :hooks

    # Initialize an Observer
    #
    # @api public
    def initialize(machine)
      @machine = machine
      @machine.subscribe(self)
      @hooks = FiniteMachine::Hooks.new
    end

    # Evaluate in current context
    #
    # @api private
    def call(&block)
      instance_eval(&block)
    end

    # Register callback for a given event type
    #
    # @param [Symbol, FiniteMachine::HookEvent] event_type
    # @param [Array] args
    # @param [Proc]  callback
    #
    # @api public
    # TODO: throw error if event type isn't handled
    def on(event_type = HookEvent, *args, &callback)
      sync_exclusive do
        name, async, _ = args
        name = ANY_EVENT if name.nil?
        async = false if async.nil?
        ensure_valid_callback_name!(event_type, name)
        callback.extend(Async) if async == :async
        hooks.register event_type, name, callback
      end
    end

    # Unregister callback for a given event
    #
    # @api public
    def off(event_type = ANY_EVENT, name = ANY_STATE, &callback)
      sync_exclusive do
        hooks.unregister event_type, name, callback
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

    # Trigger all listeners
    #
    # @api public
    def trigger(event, *args, &block)
      sync_exclusive do
        [event.type, ANY_EVENT].each do |event_type|
          [event.state, ANY_STATE].each do |event_state|
            hooks.call(event_type, event_state) do |hook|
              handle_callback(hook, event)
              off(event_type, event_state, &hook) if hook.is_a?(Once)
            end
          end
        end
      end
    end

    private

    # Defer callback execution
    #
    # @api private
    def defer(callable, trans_event, *data)
      async_call = AsyncCall.build(machine, callable, trans_event, *data)
      machine.event_queue << async_call
    end

    # Create callable instance
    #
    # @api private
    def create_callable(hook)
      deferred_hook = proc do |_trans_event, *_data|
        machine.instance_exec(_trans_event, *_data, &hook)
      end
      Callable.new(deferred_hook)
    end

    # Handle callback and decide if run synchronously or asynchronously
    #
    # @api private
    def handle_callback(hook, event)
      data        = event.data
      trans_event = TransitionEvent.build(event.transition, *data)
      callable    = create_callable(hook)

      if hook.is_a?(Async)
        defer(callable, trans_event, *data)
        result = nil
      else
        result = callable.call(trans_event, *data)
      end

      event.transition.cancelled = (result == CANCELLED)
    end

    # Callback names including all states and events
    #
    # @return [Array[Symbol]]
    #   valid callback names
    #
    # @api private
    def callback_names
      machine.states + machine.event_names + [ANY_EVENT]
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
