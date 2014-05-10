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

    # Initialize a Transition
    #
    # @param [StateMachine] machine
    # @param [Hash] attrs
    #
    # @api public
    def initialize(machine, attrs = {})
      @machine     = machine
      @name        = attrs.fetch(:name, DEFAULT_STATE)
      @map         = FiniteMachine::StateParser.new(attrs).parse_states
      @from_states = @map.keys
      @to_states   = @map.values
      @from_state  = @from_states.first
      @if          = Array(attrs.fetch(:if, []))
      @unless      = Array(attrs.fetch(:unless, []))
      @conditions  = make_conditions
      @cancelled   = false
    end

    # Decide :to state from available transitions for this event
    #
    # @return [Symbol]
    #
    # @api public
    def to_state
      machine.transitions[name][from_state]
    end

    # Reduce conditions
    #
    # @api private
    def make_conditions
      @if.map { |c| Callable.new(c) } +
        @unless.map { |c| Callable.new(c).invert }
    end

    # Check if moved to different state
    #
    # @param [Symbol] state
    #   the current state name
    #
    # @return [Boolean]
    #
    # @api public
    def different?(state)
      map[state] == state || map[ANY_STATE] == state
    end

    # Add transition to the machine
    #
    # @return [Transition]
    #
    # @api private
    def define
      from_states.each do |from|
        machine.transitions[name][from] = map[from] || ANY_STATE
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
      _name       = name
      bang_name   = "#{_name}!"

      machine.singleton_class.class_eval do
        undef_method(_name)     if method_defined?(_name)
        undef_method(bang_name) if method_defined?(bang_name)
      end
      define_transition(name)
      define_event_bang(name)
    end

    # Define transition event
    #
    # @api private
    def define_transition(name)
      _transition = self
      machine.send(:define_singleton_method, name) do |*args, &block|
        transition(_transition, *args, &block)
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

    # Execute current transition
    #
    # @return [nil]
    #
    # @api private
    def call
      sync_exclusive do
        return if cancelled
        transitions     = machine.transitions[name]
        self.from_state = machine.state
        machine.state   = transitions[machine.state] || transitions[ANY_STATE] || name
        machine.initial_state = machine.state if from_state == DEFAULT_STATE
      end
    end

    # Return transition name
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
