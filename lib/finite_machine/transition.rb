# frozen_string_literal: true

require_relative "callable"
require_relative "threadable"

module FiniteMachine
  # Class describing a transition associated with a given event
  #
  # The {Transition} is created with the `event` helper.
  #
  # @example Converting event into {Transition}
  #   event :go, :red => :green
  #
  #   will be translated to
  #
  #   Transition.new(context, :go, {states: {:red => :green}})
  #
  # @api private
  class Transition
    include Threadable

    # The event name
    attr_threadsafe :name

    # Predicates before transitioning
    attr_threadsafe :conditions

    # The current state machine context
    attr_threadsafe :context

    # All states for this transition event
    attr_threadsafe :states

    # Initialize a Transition
    #
    # @example
    #   attributes = {states: {green: :yellow}}
    #   Transition.new(context, :go, attributes)
    #
    # @param [Object] context
    #   the context this transition evaluets conditions in
    #
    # @param [Hash] attrs
    #
    # @return [Transition]
    #
    # @api public
    def initialize(context, name, attrs = {})
      @context     = context
      @name        = name
      @states      = attrs.fetch(:states, {})
      @if          = Array(attrs.fetch(:if, []))
      @unless      = Array(attrs.fetch(:unless, []))
      @conditions  = make_conditions
      freeze
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
      states[from] || states[ANY_STATE]
    end

    # Return transition name
    #
    # @example
    #   transition = Transition.new(context, name: :go)
    #   transition.to_s # => "go"
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
      transitions = @states.map { |from, to| "#{from} -> #{to}" }.join(", ")
      "<##{self.class} @name=#{@name}, @transitions=#{transitions}, " \
        "@when=#{@conditions}>"
    end
  end # Transition
end # FiniteMachine
