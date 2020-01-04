# frozen_string_literal: true

require_relative 'transition_builder'

module FiniteMachine
  # A class responsible for merging choice options
  class ChoiceMerger
    # Initialize a ChoiceMerger
    #
    # @param [StateMachine] machine
    # @param [String] name
    # @param [Hash] transitions
    #   the transitions and attributes
    #
    # @api private
    def initialize(machine, name, transitions = {})
      @machine     = machine
      @name        = name
      @transitions = transitions
    end

    # Create choice transition
    #
    # @example
    #   event :stop, from: :green do
    #     choice :yellow
    #   end
    #
    # @param [Symbol] to
    #   the to state
    # @param [Hash] conditions
    #   the conditions associated with this choice
    #
    # @return [FiniteMachine::Transition]
    #
    # @api public
    def choice(to, conditions = {})
      transition_builder = TransitionBuilder.new(@machine, @name,
                                                 @transitions.merge(conditions))
      transition_builder.call(@transitions[:from] => to)
    end
    alias_method :default, :choice
  end # ChoiceMerger
end # FiniteMachine
