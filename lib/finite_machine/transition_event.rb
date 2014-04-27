# encoding: utf-8

module FiniteMachine
  # A class representing a callback transition event
  class TransitionEvent

    attr_accessor :from

    attr_accessor :to

    attr_accessor :name

    # Build a transition event
    #
    # @return [self]
    #
    # @api private
    def self.build(transition)
      instance = new
      instance.from = transition.from_state
      instance.to   = transition.to
      instance.name = transition.name
      instance
    end
  end # TransitionEvent
end # FiniteMachine
