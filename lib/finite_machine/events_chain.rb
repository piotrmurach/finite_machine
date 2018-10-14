# frozen_string_literal: true

require 'concurrent/map'
require 'forwardable'

require_relative 'threadable'
require_relative 'undefined_transition'

module FiniteMachine
  # A class responsible for storing events and their transitions.
  #
  # Used internally by {StateMachine}.
  #
  # @api private
  class EventsChain
    extend Forwardable

    def_delegators :@events, :empty?, :size

    # Initialize a EventsChain
    #
    # @api private
    def initialize
      @events = Concurrent::Map.new
    end

    # Check if event is present
    #
    # @example
    #   events_chain.exists?(:go) # => true
    #
    # @param [Symbol] name
    #   the event name
    #
    # @return [Boolean]
    #   true if event is present, false otherwise
    #
    # @api public
    def exists?(name)
      @events.key?(name)
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
        @events[name] << transition
      else
        @events[name] = [transition]
      end
      self
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
      @events.fetch(name) { [] }
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
      @events.keys
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
      @events.values.flatten.map(&:states).map(&:to_a).flatten.uniq
    end

    # Retrieves all state transitions
    #
    # @return [Array[Hash]]
    #
    # @api public
    def state_transitions
      @events.values.flatten.map(&:states)
    end

    # Retrieve from states for the event name
    #
    # @param [Symbol] event_name
    #
    # @example
    #   events_chain.states_for(:start) # => [:yellow, :green]
    #
    # @api public
    def states_for(name)
      find(name).map(&:states).flat_map(&:keys)
    end

    # Check if event is valid and transition can be performed
    #
    # @return [Boolean]
    #
    # @api public
    def can_perform?(name, from_state, *conditions)
      !match_transition_with(name, from_state, *conditions).nil?
    end

    # Check if event has branching choice transitions or not
    #
    # @example
    #   events_chain.choice_transition?(:go, :green) # => true
    #
    # @param [Symbol] name
    #   the event name
    #
    # @param [Symbol] from_state
    #   the transition from state
    #
    # @return [Boolean]
    #   true if transition has any branches, false otherwise
    #
    # @api public
    def choice_transition?(name, from_state)
      find(name).select { |trans| trans.matches?(from_state) }.size > 1
    end

    # Find transition without checking conditions
    #
    # @param [Symbol] name
    #   the event name
    #
    # @param [Symbol] from_state
    #   the transition from state
    #
    # @return [Transition, nil]
    #   returns transition, nil otherwise
    #
    # @api private
    def match_transition(name, from_state)
      find(name).find { |trans| trans.matches?(from_state) }
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
    def match_transition_with(name, from_state, *conditions)
      find(name).find do |trans|
        trans.matches?(from_state) &&
        trans.check_conditions(*conditions)
      end
    end

    # Select transition that matches conditions
    #
    # @param [Symbol] name
    #   the event name
    # @param [Symbol] from_state
    #   the transition from state
    # @param [Array[Object]] conditions
    #   the conditional data
    #
    # @return [Transition]
    #
    # @api public
    def select_transition(name, from_state, *conditions)
      if choice_transition?(name, from_state)
        match_transition_with(name, from_state, *conditions)
      else
        match_transition(name, from_state)
      end
    end

    # Find state that this machine can move to
    #
    # @example
    #   evenst_chain.move_to(:go, :green) # => :red
    #
    # @param [Symbol] name
    #   the event name
    #
    # @param [Symbol] from_state
    #   the transition from state
    #
    # @param [Array] conditions
    #   the data associated with this transition
    #
    # @return [Symbol]
    #   the transition `to` state
    #
    # @api public
    def move_to(name, from_state, *conditions)
      transition = select_transition(name, from_state, *conditions)
      transition ||= UndefinedTransition.new(name)

      transition.to_state(from_state)
    end

    # Set status to cancelled for all transitions matching event name
    #
    # @param [Symbol] name
    #   the event name
    #
    # @return [nil]
    #
    # @api public
    def cancel_transitions(event_name)
      @events[event_name].each do |trans|
        trans.cancelled = true
      end
    end

    # Reset chain
    #
    # @return [self]
    #
    # @api public
    def clear
      @events.clear
      self
    end

    # Return string representation of this chain
    #
    # @return [String]
    #
    # @api public
    def to_s
      @events.each_pair.to_h.to_s
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
      "<##{self.class} @events=#{@events.each_pair.to_h}>"
    end
  end # EventsChain
end # FiniteMachine
