# encoding: utf-8

module FiniteMachine
  # Module for responsible for safety checks against known methods
  module Safety

    EVENT_CONFLICT_MESSAGE = \
      "You tried to define an event named \"%{name}\", however this would " \
      "generate \"%{type}\" method \"%{method}\", which is already defined " \
      "by %{source}"

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
        raise FiniteMachine::AlreadyDefinedError, EVENT_CONFLICT_MESSAGE % {
          name: event_name,
          type: :instance,
          method: method_name,
          source: 'FiniteMachine'
        }
      end
    end

    private

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
