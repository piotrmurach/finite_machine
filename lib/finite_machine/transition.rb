# frozen_string_literal: true

require_relative 'callable'
require_relative 'threadable'

module FiniteMachine
  # Class describing a transition associated with a given event
  class Transition
    include Threadable

    # The event name
    attr_threadsafe :name

    # Predicates before transitioning
    attr_threadsafe :conditions

    # The current state machine context
    attr_threadsafe :context

    # Check if transition should be cancelled
    attr_threadsafe :cancelled

    # All states for this transition event
    attr_threadsafe :states

    # Initialize a Transition
    #
    # @example
    #   attributes = {parsed_states: {green: :yellow}}
    #   Transition.new(context, attributes)
    #
    # @param [Object] context
    #   the context this transition evaluets conditions in
    #
    # @param [Hash] attrs
    #
    # @return [Transition]
    #
    # @api public
    def initialize(context, attrs = {})
      @context     = context
      @name        = attrs[:name]
      @states      = attrs.fetch(:states, {})
      @if          = Array(attrs.fetch(:if, []))
      @unless      = Array(attrs.fetch(:unless, []))
      @conditions  = make_conditions
      @cancelled   = attrs.fetch(:cancelled, false)
    end

    # Check if this transition is cancelled or not
    #
    # @return [Boolean]
    #
    # @api public
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
    # @param [Array[Object]] args
    #   the arguments for the condition
    #
    # @return [Boolean]
    #
    # @api private
    def check_conditions(*args)
      conditions.all? do |condition|
        condition.call(context, *args)
      end
    end

    # Check if this transition matches from state
    #
    # @param [Symbol] from
    #   the from state to match against
    #
    # @example
    #   transition = Transition.new(context, states: {:green => :red})
    #   transition.matches?(:green) # => true
    #
    # @return [Boolean]
    #   Return true if match is found, false otherwise.
    #
    # @api public
    def matches?(from)
      states.keys.any? { |state| [ANY_STATE, from].include?(state) }
    end

    # Find to state for this transition given the from state
    #
    # @param [Symbol] from
    #   the from state to check
    #
    # @example
    #   transition = Transition.new(context, states: {:green => :red})
    #   transition.to_state(:green) # => :red
    #
    # @return [Symbol]
    #   the to state
    #
    # @api public
    def to_state(from)
      if cancelled?
        from
      else
        states[from] || states[ANY_STATE]
      end
    end

    # Return transition name
    #
    # @example
    #   transition = Transition.new(context, name: :go)
    #   transition.to_s # => 'go'
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
