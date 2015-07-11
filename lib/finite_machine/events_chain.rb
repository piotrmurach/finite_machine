# encoding: utf-8

module FiniteMachine
  # A class responsible for storing chain of events
  class EventsChain
    include Threadable
    extend Forwardable

    # The current state machine
    attr_threadsafe :machine

    # The chain of events
    attr_threadsafe :chain

    def_delegators :@chain, :[], :empty?

    # Initialize a EventsChain
    #
    # @param [StateMachine] machine
    #   the state machine
    #
    # @api public
    def initialize(machine)
      @machine = machine
      @chain   = {}
    end

    # Insert transition under given event name
    #
    # @param [Symbol] name
    #  the event name
    #
    # @param [Transition]
    #
    # @return [nil]
    #
    # @api public
    def insert(name, transition)
      return false unless chain[name]
      chain[name] << transition
    end

    # Add event under name
    #
    # @return [nil]
    #
    # @api public
    def add(name, event)
      chain[name] = event
    end

    # Check if event is valid and transition can be performed
    #
    # @return [Boolean]
    #
    # @api public
    def valid_event?(event_name, *args, &block)
      next_transition(event_name).valid?(*args, &block)
    end

    # Find next transition
    #
    # @return [Transition]
    #   the next available transition
    #
    # @api private
    def next_transition(name)
      sync_shared do
        chain[name].state_transitions.find { |transition| transition.current? } ||
        chain[name].state_transitions.first
      end
    end

    # Find transition matching conditions
    #
    # @param [Array[Object]] args
    #
    # return [Transition]
    #
    # @api private
    def find_transition(name, *conditions)
      sync_shared do
        chain[name].state_transitions.find do |trans|
          trans.current? && trans.check_conditions(*conditions)
        end
      end
    end

    # Select transition that passes constraints condition
    #
    # @param [Symbol] name
    #   the event name
    #
    # @return [Transition]
    #
    # @api public
    def select_transition(name, *conditions)
      find_transition(name, *conditions)
    end

    # Examine choice transitions to find one matching condition
    #
    # @param [Symbol] name
    #   the event name
    #
    # @param [Symbol] from_state
    #   the current context from_state
    #
    # @return [Transition]
    #   The choice transition that matches
    #
    # @api public
    def select_choice_transition(name, from_state, *args, &block)
      chain[name].state_transitions.find do |trans|
        [from_state, ANY_STATE].include?(trans.from_state) &&
        trans.check_conditions(*args, &block)
      end
    end

    # Check if any of the transition constraints passes
    #
    # @param [Symbol] name
    #   the event name
    #
    # @return [Boolean]
    #
    # @api public
    def check_choice_conditions(name, *conditions, &block)
      !find_transition(name, *conditions).nil?
    end

    # Reset chain
    #
    # @return [self]
    #
    # @api public
    def clear
      @chain.clear
      self
    end

    # Return string representation of this chain
    #
    # @return [String]
    #
    # @api public
    def to_s
      chain.to_s
    end

    # Inspect chain content
    #
    # @example
    #   events_chain.inspect
    #
    # @return [String]
    #
    # @api public
    def inspect
      "<##{self.class} @chain=#{chain.inspect}>"
    end
  end # EventsChain
end # FiniteMachine
