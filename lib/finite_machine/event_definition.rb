# frozen_string_literal: true

module FiniteMachine
  # A class responsible for defining event methods on state machine
  #
  # Used to add event definitions from {TransitionBuilder} to
  # the {StateMachine} to obtain convenience helpers.
  #
  # @api private
  class EventDefinition
    # The current state machine
    attr_reader :machine

    # Initialize an EventDefinition
    #
    # @param [StateMachine] machine
    #
    # @api private
    def initialize(machine)
      @machine = machine
    end

    # Define transition event names as state machine events
    #
    # @param [Symbol] event_name
    #   the event name for which definition is created
    #
    # @return [nil]
    #
    # @api public
    def apply(event_name, silent = false)
      define_event_transition(event_name, silent)
      define_event_bang(event_name, silent)
    end

    private

    # Define transition event
    #
    # @param [Symbol] event_name
    #   the event name
    #
    # @param [Boolean] silent
    #   if true don't trigger callbacks, otherwise do
    #
    # @return [nil]
    #
    # @api private
    def define_event_transition(event_name, silent)
      machine.send(:define_singleton_method, event_name) do |*data, &block|
        method = silent ? :transition : :trigger
        machine.public_send(method, event_name, *data, &block)
      end
    end

    # Define event that skips validations and callbacks
    #
    # @param [Symbol] event_name
    #   the event name
    #
    # @param [Boolean] silent
    #   if true don't trigger callbacks, otherwise do
    #
    # @return [nil]
    #
    # @api private
    def define_event_bang(event_name, silent)
      machine.send(:define_singleton_method, "#{event_name}!") do |*data, &block|
        method = silent ? :transition! : :trigger!
        machine.public_send(method, event_name, *data, &block)
      end
    end
  end # EventBuilder
end # FiniteMachine
