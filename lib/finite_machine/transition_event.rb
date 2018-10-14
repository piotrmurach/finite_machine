# frozen_string_literal: true

require_relative 'threadable'

module FiniteMachine
  # A class representing a callback transition event
  #
  # Used internally by {Observer}
  #
  # @api private
  class TransitionEvent
    include Threadable

    # This event from state name
    #
    # @return [Object]
    #
    # @api public
    attr_threadsafe :from

    # This event to state name
    #
    # @return [Object]
    #
    # @api public
    attr_threadsafe :to

    # This event name
    #
    # @api public
    attr_threadsafe :name

    # Build a transition event
    #
    # @param [FiniteMachine::Transition] transition
    #
    # @return [self]
    #
    # @api private
    # def initialize(transition, *data)
    def initialize(hook_event, to)
      @name = hook_event.event_name
      @from = hook_event.from
      @to   = to
      freeze
    end
  end # TransitionEvent
end # FiniteMachine
