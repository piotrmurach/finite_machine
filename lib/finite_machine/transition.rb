# encoding: utf-8

module FiniteMachine
  # Class describing a transition associated with a given event
  class Transition
    include Threadable
    include Safety

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
      _transition = new(machine, attrs)
      _transition.update_transitions
      _transition.define_state_methods
      _transition.define_event
      _transition
    end

    # Decide :to state from available transitions for this event
    #
    # @return [Symbol]
    #
    # @api public
    def to_state(*args)
      if transition_choice?
        found_trans = machine.select_transition(name, *args)
        found_trans.map[from_state]
      else
        machine.transitions[name][from_state]
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

    # Check if this transition has branching choice or not
    #
    # @return [Boolean]
    #
    # @api public
    def transition_choice?
      machine.transitions[name][from_state].is_a?(Array)
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
        machine.check_choice_conditions(name, *args, &block)
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
        if value = machine.transitions[name][from]
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

    # Define event on the machine
    #
    # @api private
    def define_event
      detect_event_conflict!(name)
      if machine.singleton_class.send(:method_defined?, name)
        machine.events_chain.insert(name, self)
      else
        define_event_transition(name)
        define_event_bang(name)
      end
    end

    # Define transition event
    #
    # @api private
    def define_event_transition(name)
      _event = FiniteMachine::Event.new(machine, name: name, silent: silent)
      _event << self
      machine.events_chain.add(name, _event)

      machine.send(:define_singleton_method, name) do |*args, &block|
        _event.call(*args, &block)
      end
    end

    # Define event that skips validations
    #
    # @api private
    def define_event_bang(name)
      machine.send(:define_singleton_method, "#{name}!") do
        transitions   = machine.transitions[name]
        machine.state = transitions.values[0]
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
