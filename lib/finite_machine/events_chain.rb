# encoding: utf-8

require 'finite_machine/undefined_transition'

module FiniteMachine
  # A class responsible for storing chain of events.
  #
  # Used internally by {StateMachine}.
  #
  # @api private
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

    # Check if event is present
    #
    # @return [Boolean]
    #   true if event is present, false otherwise
    #
    # @api public
    def exists?(name)
      !chain[name].nil?
    end

    # Add transition under name
    #
    # @param [Symbol] the event name
    #
    # @param [Transition] transition
    #   the transition to add under event name
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

    # Finds transitions for the event name
    #
    # @param [Symbol] name
    #
    # @example
    #   events_chain[:start] # => []
    #
    # @return [Array[Transition]]
    #   the transitions matching event name
    #
    # @api public
    def find(name)
      chain.fetch(name) { [] }
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

    # Retreive all unique states
    #
    # @example
    #   events_chain.states # => [:yellow, :green, :red]
    #
    # @return [Array[Symbol]]
    #   the array of all unique states
    #
    # @api public
    def states
      chain.values.flatten.map(&:states).map(&:to_a).flatten.uniq
    end

    # Retrieves all state transitions
    #
    # @return [Array[Hash]]
    #
    # @api public
    def state_transitions
      chain.values.flatten.map(&:states)
    end

    # Retrieve from states for the event name
    #
    # @param [Symbol] event_name
    #
    # @example
    #   events_chain.states_for(:start) # => [:yellow, :green]
    #
    # @api public
    def states_for(event_name)
      find(event_name).map(&:states).flat_map(&:keys)
    end

    # Check if event is valid and transition can be performed
    #
    # @return [Boolean]
    #
    # @api public
    def can_perform?(event_name, from_state, *conditions, &block)
      !transition_from(event_name, from_state, *conditions).nil?
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
      chain[name].select { |trans| trans.matches?(from_state) }.size > 1
    end

    # Find transition without checking conditions
    #
    # @param [Symbol] name
    #
    # @return [Transition]
    #
    # @api private
    def find_transition(name, from_state)
      chain[name].find { |trans| trans.matches?(from_state) }
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
    def transition_from(name, from_state, *conditions)
      chain[name].find do |trans|
        trans.matches?(from_state) &&
        trans.check_conditions(*conditions)
      end
    end

    # @api public
    def select_transition(name, from_state, *conditions)
      if choice_transition?(name, from_state)
        transition_from(name, from_state, *conditions)
      else
        find_transition(name, from_state)
      end
    end

    # Find transition can move to
    #
    # @param [Array] data
    #   the data associated with this transition
    #
    # @return [Symbol]
    #   the state transition to
    #
    # @api public
    def move_to(name, from_state, *data)
      transition = select_transition(name, from_state, *data)
      transition ||= UndefinedTransition.new(name)

      transition.to_state(from_state)
    end

    # Set cancelled status for all transitions matching event name
    #
    # @param [Symbol] name
    #   the event name
    # @param [Symbol] status
    #   true to cancel, false otherwise
    #
    # @return [nil]
    #
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
