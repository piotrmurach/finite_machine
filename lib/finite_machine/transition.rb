# encoding: utf-8

module FiniteMachine

  # Class describing a transition associated with a given event
  class Transition
    include Threadable

    attr_threadsafe :name

    # State transitioning from
    attr_threadsafe :from

    # State transitioning to
    attr_threadsafe :to

    # Predicates before transitioning
    attr_threadsafe :conditions

    # The current state machine
    attr_threadsafe :machine

    # Initialize a Transition
    #
    # @api public
    def initialize(machine, attrs = {})
      @machine    = machine
      @name       = attrs.fetch(:name, DEFAULT_STATE)
      @from, @to  = *parse_states(attrs)
      @if         = Array(attrs.fetch(:if, []))
      @unless     = Array(attrs.fetch(:unless, []))
      @conditions = make_conditions
    end

    def make_conditions
      @if.map { |c| Callable.new(c) } +
        @unless.map { |c| Callable.new(c).invert }
    end

    # Extract states from attributes
    #
    # @api private
    def parse_states(attrs)
      _attrs = attrs.dup
      [:name, :if, :unless].each { |key| _attrs.delete(key) }

      if [:from, :to].any? { |key| attrs.keys.include?(key) }
        [Array(_attrs[:from] || ANY_STATE), _attrs[:to]]
      else
        [(keys = _attrs.keys).flatten, _attrs[keys.first]]
      end
    end

    # Execute current transition
    #
    # @api private
    def call
      sync_exclusive do
        transitions = machine.transitions[name]
        machine.state = transitions[machine.state] || transitions[ANY_STATE] || name
      end
    end

    def inspect
      [@name, @from, @to, @conditions].inspect
    end

  end # Transition
end # FiniteMachine
