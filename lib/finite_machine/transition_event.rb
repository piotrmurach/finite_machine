# encoding: utf-8

module FiniteMachine
  # A class representing a callback transition event
  #
  # Used internally by {Observer}
  #
  # @api private
  class TransitionEvent
    # This event from state name
    #
    # @return [Object]
    #
    # @api public
    attr_accessor :from

    # This event to state name
    #
    # @return [Object]
    #
    # @api public
    attr_accessor :to

    # This event name
    #
    # @api public
    attr_accessor :name

    # Build a transition event
    #
    # @param [FiniteMachine::Transition] transition
    #
    # @return [self]
    #
    # @api private
    def self.build(transition, *data)
      instance = new
      instance.name = transition.name
      instance.from = transition.latest_from_state
      instance.to   = transition.to_state(*data)
      instance
    end
  end # TransitionEvent
end # FiniteMachine
