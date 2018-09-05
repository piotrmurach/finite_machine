# frozen_string_literal: true

module FiniteMachine
  # Stand in for lack of matching transition.
  #
  # Used internally by {EventsChain}
  #
  # @api private
  class UndefinedTransition
    # Initialize an undefined transition
    #
    # @api private
    def initialize(name)
      @name = name
      freeze
    end

    def to_state(from)
      from
    end

    def ==(other)
      other.is_a?(UndefinedTransition) && name == other.name
    end

    protected

    attr_reader :name

  end # UndefinedTransition
end # FiniteMachine
