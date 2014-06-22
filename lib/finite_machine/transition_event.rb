# encoding: utf-8

module FiniteMachine
  # A class representing a callback transition event
  class TransitionEvent

    attr_accessor :from

    attr_accessor :to

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
      instance.from = transition.from_state
      instance.to   = transition.to_state(*data)
      instance
    end
  end # TransitionEvent
end # FiniteMachine
