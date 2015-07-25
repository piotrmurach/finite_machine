# encoding: utf-8

require 'finite_machine/undefined_transition'

module FiniteMachine
  # A class responsible for storing chain of events
  class EventsChain
    include Threadable
    extend Forwardable

    # The chain of events
    attr_threadsafe :chain

    def_delegators :@chain, :empty?

    # Initialize a EventsChain
    #
    # @api public
    def initialize
      @chain = {}
    end

    def exists?(name)
      !chain[name].nil?
    end

    def find(name)
      chain.fetch(name) { UndefinedTransition.new(name) }
    end
    alias_method :[], :find

    # Retrieve all event names
    #
    # @example
    #   events_chain.events # => [:init, :start, :stop]
    #
    # @return [Array[Symbol]]
    #   All event names
    #
    # @api public
    def events
      chain.keys
    end

    # Retreive all states
    #
    # @example
    #   events_chain.states # => [:yellow, :green, :red]
    #
    # @api public
    def states
      chain.values.flatten.map(&:states).map(&:to_a).flatten.uniq
    end

    # Add event under name
    #
    # @return [nil]
    #
    # @api public
    def add(name, transition)
      if exists?(name)
        chain[name] << transition
      else
        chain[name] = [transition]
      end
    end

    # Check if event is valid and transition can be performed
    #
    # @return [Boolean]
    #
    # @api public
    def can_perform?(event_name, from_state, *conditions, &block)
      !transition_from(event_name, from_state, *conditions).nil?
    end

    # Find next transition
    #
    # @return [Transition]
    #   the next available transition
    #
    # @api private
    def next_transition(name)
      sync_shared do
        chain[name].find(&:current?) || UndefinedTransition.new(name)
      end
    end

    # Find transition matching conditions
    #
    # @param [Symbol] name
    #
    # return [Transition]
    #
    # @api private
    def find_transition(name, from_state)
      chain[name].find do |trans|
        [ANY_STATE, from_state].include?(trans.from_state)
      end
    end

    # Check if event has branching choice transitions or not
    #
    # @example
    #   events_chain.choice_transition?(:go, :green) # => true
    #
    # @return [Boolean]
    #
    # @api public
    def choice_transition?(name, from_state)
      chain[name].select do |trans|
        [ANY_STATE, from_state].include?(trans.from_state)
      end.size > 1
    end

    # Examine transitions for event name that start in from state
    # and find one matching condition.
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
    def transition_from(name, from_state, *conditions, &block)
      chain[name].find do |trans|
        [ANY_STATE, from_state].include?(trans.from_state) &&
        trans.check_conditions(*conditions, &block)
      end
    end

    # @return [Symbol]
    #  The to state
    #
    # @api public
    def detect_to_state(name, from_state, *conditions, &block)
      transition = transition_from(name, from_state, *conditions)
      if transition.nil?
        from_state
      else
        transition.states[from_state] || transition.states[ANY_STATE]
      end
    end

    # @api public
    def cancel_transitions(name, status)
      chain[name].each do |trans|
        trans.cancelled = status
      end
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
