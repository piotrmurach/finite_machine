# encoding: utf-8

module FiniteMachine
  # A class responsible for building event methods
  class EventBuilder
    include Threadable
    include Safety

    # The current state machine
    attr_threadsafe :machine

    # Initialize an EventBuilder
    #
    # @param [FiniteMachine::StateMachine] machine
    #
    # @api private
    def initialize(machine)
      @machine = machine
    end

    # Build state machine events
    #
    # @param [FiniteMachine::Transition] transition
    #   the transition for which event is build
    #
    # @return [FiniteMachine::Transition]
    #
    # @api private
    def call(transition)
      name = transition.name
      detect_event_conflict!(name)
      if machine.singleton_class.send(:method_defined?, name)
        machine.events_chain.insert(name, transition)
      else
        define_event_transition(name, transition)
        define_event_bang(name)
      end
      transition
    end

    private

    # Define transition event
    #
    # @param [Symbol] name
    #   the event name
    #
    # @param [FiniteMachine::Transition] transition
    #   the transition this event is associated with
    #
    # @return [nil]
    #
    # @api private
    def define_event_transition(name, transition)
      silent = transition.silent
      _event = FiniteMachine::Event.new(machine, name: name, silent: silent)
      _event << transition
      machine.events_chain.add(name, _event)

      machine.send(:define_singleton_method, name) do |*args, &block|
        _event.call(*args, &block)
      end
    end

    # Define event that skips validations
    #
    # @param [Symbol] name
    #   the event name
    #
    # @return [nil]
    #
    # @api private
    def define_event_bang(name)
      machine.send(:define_singleton_method, "#{name}!") do
        transitions   = machine.transitions[name]
        machine.state = transitions.values[0]
      end
    end
  end # EventBuilder
end # FiniteMachine
