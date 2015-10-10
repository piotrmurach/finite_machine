# encoding: utf-8

module FiniteMachine
  # Stand in for lack of matching transition.
  #
  # Used internally by {EventsChain}
  #
  # @api private
  class UndefinedTransition
    include Threadable

    # Initialize an undefined transition
    #
    # @api private
    def initialize(name)
      self.name = name
    end

    def to_state(from)
      from
    end

    def ==(other)
      other.is_a?(UndefinedTransition) && name == other.name
    end

    protected

    attr_threadsafe :name

  end # UndefinedTransition
end # FiniteMachine
