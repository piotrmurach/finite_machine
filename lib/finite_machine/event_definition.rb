# encoding: utf-8

module FiniteMachine
  # A class responsible for defining event methods on state machine
  #
  # Used to add event definitions from {TransitionBuilder} to
  # the {StateMachine} to obtain convenience helpers.
  #
  # @api private
  class EventDefinition
    include Threadable

    # The current state machine
    attr_threadsafe :machine

    # Initialize an EventDefinition
    #
    # @param [StateMachine] machine
    #
    # @api private
    def initialize(machine)
      self.machine = machine
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
      define_event_bang(event_name)
    end

    private

    # Define transition event
    #
    # @param [Symbol] event_name
    #   the event name
    #
    # @return [nil]
    #
    # @api private
    def define_event_transition(event_name, silent)
      machine.send(:define_singleton_method, event_name) do |*data|
        if silent
          machine.send(:transition!, event_name, *data)
        else
          machine.send(:transition, event_name, *data)
        end
      end
    end

    # Define event that skips validations and callbacks
    #
    # @param [Symbol] event_name
    #   the event name
    #
    # @return [nil]
    #
    # @api private
    def define_event_bang(event_name)
      machine.send(:define_singleton_method, "#{event_name}!") do
        transitions = machine.events_chain.find(event_name)
        machine.state = transitions.map(&:states).flat_map(&:values)[0]
      end
    end
  end # EventBuilder
end # FiniteMachine
