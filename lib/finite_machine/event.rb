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

    # Find next transition
    #
    # @return [Transition]
    #   the next available transition
    #
    # @api private
    def next_transition
      sync_shared do
        state_transitions.find { |transition| transition.current? } ||
        state_transitions.first
      end
    end

    # Find transition matching conditions
    #
    # @param [Array[Object]] args
    #
    # return [Transition]
    #
    # @api private
    def find_transition(*args)
      sync_shared do
        state_transitions.find do |trans|
          trans.current? && trans.check_conditions(*args)
        end
      end
    end

    # Trigger this event
    #
    # If silent option is passed the event will not fire any callbacks
    #
    # @example
    #   transition = Event.new(machine, {})
    #   transition.trigger
    #
    # @return [Boolean]
    #   true is transition succeeded, false otherwise
    #
    # @api public
    def trigger(*data)
      sync_exclusive do
        event_transition = next_transition
        if !event_transition.cancelled? && event_transition.silent?
          machine.send(:move_state, *event_transition.execute(*data))
        else
          machine.send(:transition, event_transition, *data)
        end
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
