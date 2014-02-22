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

    # Register callback for a given event.
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

    def listen_on(type, *args, &callback)
      state_or_event = args.first
      if machine.states.include?(state_or_event) || state_or_event == ANY_STATE_HOOK
        on :"#{type}state", *args, &callback
      elsif machine.event_names.include?(state_or_event)  || state_or_event == ANY_EVENT_HOOK
        on :"#{type}action", *args, &callback
      else
        on :"#{type}state", *args, &callback
        on :"#{type}action", *args, &callback
      end
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

    def method_missing(method_name, *args, &block)
      _, event_name, callback_name = *method_name.to_s.match(/^(on_\w+?)_(\w+)$/)
      if callback_names.include?(callback_name.to_sym)
        send(event_name, callback_name.to_sym, *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      _, callback_name = *method_name.to_s.match(/^(on_\w+?)_(\w+)$/)
      callback_names.include?(callback_name.to_sym)
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
      hook.call(trans_event, *event.data)
    end

    def trigger(event, *args, &block)
      sync_exclusive do
        [event.type, ANY_EVENT].each do |event_type|
          [event.state, ANY_STATE,
           ANY_STATE_HOOK, ANY_EVENT_HOOK].each do |event_state|
            hooks.call(event_type, event_state, event) do |hook|
              run_callback(hook, event)
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
        raise InvalidCallbackNameError, "#{name} is not a valid callback name." +
          " Valid callback names are #{callback_names.to_a.inspect}"
      end
    end

  end # Observer
end # FiniteMachine
