# encoding: utf-8

module FiniteMachine
  # Class describing a transition associated with a given event
  class Transition
    include Threadable

    attr_threadsafe :name

    # State transitioning from
    attr_threadsafe :from_states

    # State transitioning to
    attr_threadsafe :to_states

    # Predicates before transitioning
    attr_threadsafe :conditions

    # The current state machine
    attr_threadsafe :machine

    # The original from state
    attr_threadsafe :from_state

    # Check if transition should be cancelled
    attr_threadsafe :cancelled

    # All states for this transition event
    attr_threadsafe :map

    # Silence callbacks
    attr_threadsafe :silent

    # Initialize a Transition
    #
    # @param [StateMachine] machine
    # @param [Hash] attrs
    #
    # @api public
    def initialize(machine, attrs = {})
      @machine     = machine
      @name        = attrs.fetch(:name, DEFAULT_STATE)
      @map         = attrs.fetch(:parsed_states, {})
      @silent      = attrs.fetch(:silent, false)
      @from_states = @map.keys
      @to_states   = @map.values
      @from_state  = @from_states.first
      @if          = Array(attrs.fetch(:if, []))
      @unless      = Array(attrs.fetch(:unless, []))
      @conditions  = make_conditions
      @cancelled   = false
    end

    # Create transition with associated helper methods
    #
    # @param [FiniteMachine::StateMachine] machine
    # @param [Hash] attrs
    #
    # @example
    #   Transition.create(machine, {})
    #
    # @return [FiniteMachine::Transition]
    #
    # @api public
    def self.create(machine, attrs = {})
      transition = new(machine, attrs)
      transition.update_transitions
      transition.define_state_methods

      builder = EventBuilder.new(machine)
      builder.call(transition)
    end

    # Decide :to state from available transitions for this event
    #
    # @return [Symbol]
    #
    # @api public
    def to_state(*args)
      if transition_choice?
        found_trans = machine.select_choice_transition(name, from_state, *args)

        if found_trans.nil?
          from_state
        else
          found_trans.map[from_state] || found_trans.map[ANY_STATE]
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
      map[state] == state || (map[ANY_STATE] == state && from_state == state)
    end

    # Check if from matches current state
    #
    # @example
    #   transition.current? # => true
    #
    # @return [Boolean]
    #   Return true if match is found, false otherwise.
    #
    # @api public
    def current?
      [machine.current, ANY_STATE].any? { |state| state == from_state }
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

    # Check if transition can be performed according to constraints
    #
    # @param [Array] args
    #
    # @param [Proc] block
    #
    # @return [Boolean]
    #
    # @api public
    def valid?(*args, &block)
      if transition_choice?
        machine.events_chain[name].state_transitions.select { |trans|
          trans.check_conditions(*args, &block)
        }.any?(&:current?)
      else
        check_conditions(*args, &block)
      end
    end

    # Add transition to the machine
    #
    # @return [FiniteMachine::Transition]
    #
    # @api private
    def update_transitions
      from_states.each do |from|
        if (value = machine.transitions[name][from])
          machine.transitions[name][from] = [value, map[from]].flatten
        else
          machine.transitions[name][from] = map[from] || ANY_STATE
        end
      end
    end

    # Define helper state mehods for the transition states
    #
    # @api private
    def define_state_methods
      from_states.concat(to_states).each { |state| define_state_method(state) }
    end

    # Define state helper method
    #
    # @param [Symbol] state
    #
    # @api private
    def define_state_method(state)
      return if machine.respond_to?("#{state}?")
      machine.send(:define_singleton_method, "#{state}?") do
        machine.is?(state.to_sym)
      end
    end

    # Set state on the machine
    #
    # @api private
    def update_state(*args)
      if transition_choice?
        found_trans   = machine.select_transition(name, *args)
        machine.state = found_trans.to_states.first
      else
        transitions   = machine.transitions[name]
        machine.state = transitions[machine.state] || transitions[ANY_STATE] || name
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

    # Execute current transition
    #
    # @return [nil]
    #
    # @api private
    def call(*args)
      sync_exclusive do
        return if cancelled
        self.from_state = machine.state
        update_state(*args)
        machine.previous_state = machine.state
        machine.initial_state = machine.state if from_state == DEFAULT_STATE
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
      transitions = @map.map { |from, to| "#{from} -> #{to}" }.join(', ')
      "<##{self.class} @name=#{@name}, @transitions=#{transitions}, @when=#{@conditions}>"
    end
  end # Transition
end # FiniteMachine
