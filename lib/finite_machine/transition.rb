# encoding: utf-8

module FiniteMachine
  # Class describing a transition associated with a given event
  class Transition
    include Threadable

    # The event name
    attr_threadsafe :name

    # Predicates before transitioning
    attr_threadsafe :conditions

    # The current state machine
    attr_threadsafe :machine

    # The original from state
    attr_threadsafe :from_state

    # Check if transition should be cancelled
    attr_threadsafe :cancelled

    # All states for this transition event
    attr_threadsafe :states

    # Silence callbacks
    attr_threadsafe :silent

    # Initialize a Transition
    #
    # @example
    #   attributes = {parsed_states: {green: :yellow}, silent: true}
    #   Transition.new(machine, attrbiutes)
    #
    # @param [StateMachine] machine
    #
    # @param [Hash] attrs
    #
    # @return [Transition]
    #
    # @api public
    def initialize(machine, attrs = {})
      @machine     = machine
      @name        = attrs[:name]
      @states      = attrs.fetch(:parsed_states, {})
      @silent      = attrs.fetch(:silent, false)
      @from_state  = @states.keys.first
      @if          = Array(attrs.fetch(:if, []))
      @unless      = Array(attrs.fetch(:unless, []))
      @conditions  = make_conditions
      @cancelled   = false
    end

    def silent?
      @silent
    end

    def cancelled?
      @cancelled
    end

    # Reduce conditions
    #
    # @return [Array[Callable]]
    #
    # @api private
    def make_conditions
      @if.map { |c| Callable.new(c) } +
        @unless.map { |c| Callable.new(c).invert }
    end

    # Verify conditions returning true if all match, false otherwise
    #
    # @return [Boolean]
    #
    # @api private
    def check_conditions(*args, &block)
      conditions.all? do |condition|
        condition.call(machine.target, *args, &block)
      end
    end

    # Check if this transition matches from state
    #
    # @param [Symbol] from
    #   the from state to match against
    #
    # @example
    #   transition.matches?(:green) # => true
    #
    # @return [Boolean]
    #   Return true if match is found, false otherwise.
    #
    # @api public
    def matches?(from)
      states.keys.any? { |state| [ANY_STATE, from].include?(state) }
    end

    # Return transition name
    #
    # @return [String]
    #
    # @api public
    def to_s
      @name.to_s
    end

    # Return string representation
    #
    # @return [String]
    #
    # @api public
    def inspect
      transitions = @states.map { |from, to| "#{from} -> #{to}" }.join(', ')
      "<##{self.class} @name=#{@name}, @transitions=#{transitions}, @when=#{@conditions}>"
    end
  end # Transition
end # FiniteMachine
