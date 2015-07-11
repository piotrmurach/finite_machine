# encoding: utf-8

module FiniteMachine
  # A class representing event with transitions
  #
  # Used by {EventDefinition} to create events.
  #
  # @api private
  class Event
    include Comparable
    include Threadable

    # The name of this event
    #
    # @return [Symbol]
    attr_threadsafe :name

    # The state transitions for this event
    #
    # @return [Array[Transition]]
    attr_threadsafe :state_transitions

    # The reference to the state machine for this event
    #
    # @return [StateMachine]
    attr_threadsafe :machine

    # Initialize an Event
    #
    # @api private
    def initialize(machine, attrs = {})
      @machine = machine
      @name    = attrs.fetch(:name, DEFAULT_STATE)
      @state_transitions = []
      freeze
    end

    protected :machine

    # Add transition for this event
    #
    # @param [FiniteMachine::Transition] transition
    #
    # @example
    #   event << FiniteMachine::Transition.new machine, :a => :b
    #
    # @return [Event]
    #
    # @api public
    def <<(transition)
      sync_exclusive do
        Array(transition).flatten.each { |trans| state_transitions << trans }
      end
      self
    end
    alias_method :add, :<<

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
      "<##{self.class} @name=#{name}, " \
      "@transitions=#{state_transitions.inspect}>"
    end

    # Compare whether the instance is greater, less then or equal to other
    #
    # @return [-1 0 1]
    #
    # @api public
    def <=>(other)
      other.is_a?(self.class) && [name, state_transitions] <=>
        [other.name, other.state_transitions]
    end
    alias_method :eql?, :==
  end # Event
end # FiniteMachine
