# encoding: utf-8

module FiniteMachine

  # A class responsible for observing state changes
  class Observer
    include Threadable

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
      @hooks = FiniteMachine::Hooks.new(machine)
    end

    # Evaluate in current context
    #
    # @api private
    def call(&block)
      instance_eval(&block)
    end

    # Register callback for a given event
    #
    # @param [Symbol] event_type
    # @param [Symbol] name
    # @param [Proc]   callback
    #
    # @api public
    def on(event_type = ANY_EVENT, name = ANY_STATE, &callback)
      sync_exclusive do
        ensure_valid_callback_name!(name)
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

    def listen_on(type, *args, &callback)
      name   = args.first
      events = []
      if machine.states.include?(name) || name == ANY_STATE_HOOK
        events << :"#{type}state"
      elsif machine.event_names.include?(name)  || name == ANY_EVENT_HOOK
        events << :"#{type}action"
      else
        events << :"#{type}state" << :"#{type}action"
      end
      events.each { |event| on event, *args, &callback }
    end

    def on_enter(*args, &callback)
      listen_on :enter, *args, &callback
    end

    def on_transition(*args, &callback)
      listen_on :transition, *args, &callback
    end

    def on_exit(*args, &callback)
      listen_on :exit, *args, &callback
    end

    def once_on_enter(*args, &callback)
      listen_on :enter, *args, &callback.extend(Once)
    end

    def once_on_transition(*args, &callback)
      listen_on :transition, *args, &callback.extend(Once)
    end

    def once_on_exit(*args, &callback)
      listen_on :exit, *args, &callback.extend(Once)
    end

    TransitionEvent = Struct.new(:from, :to, :name) do
      def build(_transition)
        self.from = _transition.from_state
        self.to   = _transition.to
        self.name = _transition.name
      end
    end

    def run_callback(hook, event)
      trans_event = TransitionEvent.new
      trans_event.build(event.transition)
      data = event.data
      deferred_hook = proc { |_trans_event, *_data|
        machine.instance_exec(_trans_event, *_data, &hook)
      }
      deferred_hook.call(trans_event, *data)
    end

    def trigger(event, *args, &block)
      sync_exclusive do
        [event.type, ANY_EVENT].each do |event_type|
          [event.state, ANY_STATE,
           ANY_STATE_HOOK, ANY_EVENT_HOOK].each do |event_state|
            hooks.call(event_type, event_state, event) do |hook|
              run_callback(hook, event)
              off(event_type, event_state, &hook) if hook.is_a?(Once)
            end
          end
        end
      end
    end

    private

    def callback_names
      @callback_names = Set.new
      @callback_names.merge machine.event_names
      @callback_names.merge machine.states
      @callback_names.merge [ANY_STATE, ANY_EVENT]
      @callback_names.merge [ANY_STATE_HOOK, ANY_EVENT_HOOK]
    end

    def ensure_valid_callback_name!(name)
      unless callback_names.include?(name)
        exception = InvalidCallbackNameError
        machine.catch_error(exception) ||
        raise(InvalidCallbackNameError, "#{name} is not a valid callback name." +
        " Valid callback names are #{callback_names.to_a.inspect}")
      end
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
      if callback_names.include?(callback_name.to_sym)
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
      callback_names.include?(:"#{callback_name}")
    end

  end # Observer
end # FiniteMachine
