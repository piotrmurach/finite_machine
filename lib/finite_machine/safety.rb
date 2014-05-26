# encoding: utf-8

module FiniteMachine
  # Module for responsible for safety checks against known methods
  module Safety
    EVENT_CONFLICT_MESSAGE = \
      "You tried to define an event named \"%{name}\", however this would " \
      "generate \"%{type}\" method \"%{method}\", which is already defined " \
      "by %{source}"

    STATE_CALLBACK_CONFLICT_MESSAGE = \
      "\"%{type}\" callback is a state listener and cannot be used " \
      "with \"%{name}\" event name. Please use on_before or on_after instead."

    EVENT_CALLBACK_CONFLICT_MESSAGE = \
      "\"%{type}\" callback is an event listener and cannot be used " \
      "with \"%{name}\" state name. Please use on_enter, on_transition or " \
      "on_exit instead."

    CALLBACK_INVALID_MESSAGE = \
      "\"%{name}\" is not a valid callback name. " \
      "Valid callback names are \"%{callbacks}"

    # Raise error when the method is already defined
    #
    # @example
    #   detect_event_conflict!(:test, "test=")
    #
    # @raise [FiniteMachine::AlreadyDefinedError]
    #
    # @return [nil]
    #
    # @api public
    def detect_event_conflict!(event_name, method_name = event_name)
      if method_already_implemented?(method_name)
        fail FiniteMachine::AlreadyDefinedError, EVENT_CONFLICT_MESSAGE % {
          name: event_name,
          type: :instance,
          method: method_name,
          source: 'FiniteMachine'
        }
      end
    end

    # Raise error when the callback name is not valid
    #
    # @example
    #   ensure_valid_callback_name!(HookEvent::Enter, ":state_name")
    #
    # @raise [FiniteMachine::InvalidCallbackNameError]
    #
    # @return [nil]
    #
    # @api public
    def ensure_valid_callback_name!(event_type, name)
      message = if wrong_event_name?(name, event_type)
        EVENT_CALLBACK_CONFLICT_MESSAGE % {
          type: "on_#{event_type.to_s}",
          name: name
        }
      elsif wrong_state_name?(name, event_type)
        STATE_CALLBACK_CONFLICT_MESSAGE % {
          type: "on_#{event_type.to_s}",
          name: name
        }
      elsif !callback_names.include?(name)
        CALLBACK_INVALID_MESSAGE % {
          name: name,
          callbacks: callback_names.to_a.inspect
        }
      else
        nil
      end
      message && fail_invalid_callback_error(message)
    end

    private

    # Check if event name exists
    #
    # @param [Symbol] name
    #
    # @param [FiniteMachine::HookEvent] event_type
    #
    # @return [Boolean]
    #
    # @api private
    def wrong_event_name?(name, event_type)
      machine.states.include?(name) &&
      !machine.event_names.include?(name) &&
      event_type < HookEvent::Anyaction
    end

    # Check if state name exists
    #
    # @param [Symbol] name
    #
    # @param [FiniteMachine::HookEvent] event_type
    #
    # @return [Boolean]
    #
    # @api private
    def wrong_state_name?(name, event_type)
      machine.event_names.include?(name) &&
      !machine.states.include?(name) &&
      event_type < HookEvent::Anystate
    end

    def fail_invalid_callback_error(message)
      exception = InvalidCallbackNameError
      machine.catch_error(exception) || fail(exception, message)
    end

    # Check if method is already implemented inside StateMachine
    #
    # @param [String] name
    #   the method name
    #
    # @return [Boolean]
    #
    # @api private
    def method_already_implemented?(name)
      method_defined_within?(name, FiniteMachine::StateMachine)
    end

    # Check if method is defined within a given class
    #
    # @param [String] name
    #   the method name
    #
    # @param [Object] klass
    #
    # @return [Boolean]
    #
    # @api private
    def method_defined_within?(name, klass)
      klass.method_defined?(name) || klass.private_method_defined?(name)
    end
  end # Safety
end # FiniteMachine
