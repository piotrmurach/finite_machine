# encoding: utf-8

module FiniteMachine
  # A list of all events and associated transitions
  #
  # Used internally by {StateMachine} to define and lookup events and 
  # their transitions.
  #
  # @api private
  class Transitions
    include Threadable
    extend Forwardable

    def_delegators :"@transitions", :keys

    def initialize
      @transitions = Hash.new { |hash, name| hash[name] = Hash.new }
    end

    # Add transition under event name
    #
    # @return [Transitions]
    #
    # @api public
    def add(name, from, to = ANY_STATE)
      if (value = transitions[name][from])
        transitions[name][from] = [value, to].flatten
      else
        transitions[name][from] = to
      end
      self
    end

    # Retrieve transitions for event name
    #
    # @return [Hash[Symbol], UndefinedTransition]
    #
    # @api public
    def find(name)
      transitions[name]
    end
    alias_method :[], :find

    private

    attr_threadsafe :transitions

  end # Transitions
end # FiniteMachine
