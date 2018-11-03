# frozen_string_literal: true

require_relative 'threadable'

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
    attr_reader :from

    # This event to state name
    #
    # @return [Object]
    #
    # @api public
    attr_reader :to

    # This event name
    #
    # @api public
    attr_reader :name

    # Build a transition event
    #
    # @param [String] event_name
    # @param [String] from
    # @param [String] to
    #
    # @return [self]
    #
    # @api private
    def initialize(event_name, from, to)
      @name = event_name
      @from = from
      @to   = to
      freeze
    end
  end # TransitionEvent
end # FiniteMachine
