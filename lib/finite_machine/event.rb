# encoding: utf-8

module FiniteMachine
  # A class representing event with transitions
  class Event
    include Threadable

    # The name of this event
    attr_threadsafe :name

    # The state transitions for this event
    attr_threadsafe :state_transitions

    # The reference to the state machine for this event
    attr_threadsafe :machine

    # @api private
    def initialize(machine, attrs = {})
      @machine = machine
      @name    = attrs.fetch(:name, DEFAULT_STATE)
      @state_transitions = []
      # TODO: add event conditions
    end

    # Add transition for this event
    #
    # @param [FiniteMachine::Transition] transition
    #
    # @example
    #   event << FiniteMachine::Transition.new machine, :a => :b
    #
    # @return [nil]
    #
    # @api public
    def <<(transition)
      sync_exclusive do
        Array(transition).flatten.each { |trans| state_transitions << trans }
      end
    end
    alias_method :add, :<<

    # Find next transition
    #
    # @return [FiniteMachine::Transition]
    #
    # @api private
    def next_transition
      state_transitions.find do |transition|
        transition.from_state == machine.current ||
          transition.from_state == ANY_STATE
      end || state_transitions.first
    end

    # Trigger this event
    #
    # @return [nil]
    #
    # @api public
    def call(*args, &block)
      sync_exclusive do
        _transition = next_transition
        machine.send(:transition, _transition, *args, &block)
      end
    end

    # Return event name
    #
    # @return [String]
    #
    # @api public
    def to_s
      name.to_s
    end

    # Return string representation
    #
    # @return [String]
    #
    # @api public
    def inspect
      "<##{self.class} @name=#{@name}, @transitions=#{state_transitions.inspect}>"
    end
  end # Event
end # FiniteMachine
