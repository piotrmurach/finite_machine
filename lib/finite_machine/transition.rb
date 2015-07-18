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

    # Decide :to state from available transitions for this event
    #
    # @return [Symbol]
    #
    # @api public
    def to_state(*args)
      if transition_choice?
        found_trans = machine.events_chain.select_choice_transition(name, from_state, *args)

        if found_trans.nil? # no choice found
          from_state
        else
          found_trans.states[from_state] || found_trans.states[ANY_STATE]
        end
      else
        available_trans = machine.transitions[name]
        available_trans[from_state] || available_trans[ANY_STATE]
      end
    end

    # Reduce conditions
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

    # Check if moved to different state or not
    #
    # @param [Symbol] state
    #   the current state name
    #
    # @return [Boolean]
    #
    # @api public
    def same?(state)
      states[state] == state || (states[ANY_STATE] == state && from_state == state)
    end

    # Check if machine current state matches any of the from states
    #
    # @example
    #   transition.current? # => true
    #
    # @return [Boolean]
    #   Return true if match is found, false otherwise.
    #
    # @api public
    def current?
      states.keys.any? { |state| state == machine.current || state == ANY_STATE }
    end

    # Check if this transition has branching choice or not
    #
    # @return [Boolean]
    #
    # @api public
    def transition_choice?
      matching = machine.transitions[name]
      [matching[from_state], matching[ANY_STATE]].any? do |match|
        match.is_a?(Array)
      end
    end

    # Find latest from state
    #
    # Note that for the exit hook the call hasn't happened yet so
    # we need to find previous to state when the from is :any.
    #
    # @return [Object] from_state
    #
    # @api private
    def latest_from_state
      sync_shared do
        from_state == ANY_STATE ? machine.previous_state : from_state
      end
    end

    # Find this transition can move to
    #
    # @param [Array] data
    #   the data associated with this transition
    #
    # @return [Symbol]
    #   the state to transition
    #
    # @api public
    def move_to(*data)
      self.from_state = machine.state
      if transition_choice?
        found_trans = machine.events_chain.find_transition(name, *data)
        found_trans.states.values.first
      else
        transitions = machine.transitions[name]
        transitions[machine.state] || transitions[ANY_STATE]
      end
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
