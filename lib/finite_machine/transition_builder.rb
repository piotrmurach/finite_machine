# encoding: utf-8

require 'finite_machine/state_parser'
require 'finite_machine/event_definition'
require 'finite_machine/state_definition'

module FiniteMachine
  # A class reponsible for building transition out of parsed states
  #
  # Used internally by {DSL} to
  #
  # @api private
  class TransitionBuilder
    include Threadable

    # The current state machine
    attr_threadsafe :machine

    attr_threadsafe :attributes

    attr_threadsafe :event_definition

    attr_threadsafe :state_definition

    # Initialize a TransitionBuilder
    #
    # @example
    #   TransitionBuilder.new(machine, {})
    #
    # @api public
    def initialize(machine, attributes = {})
      @machine = machine
      @attributes = attributes
      @event_definition = EventDefinition.new(machine)
      @state_definition = StateDefinition.new(machine)
    end

    # Creates transitions for the states
    #
    # @example
    #   transition_builder.call([:green, :yellow] => :red)
    #
    # @param [Hash[Symbol]] states
    #   The states to extract
    #
    # @return [self]
    #
    # @api public
    def call(states)
      StateParser.new(states).parse do |from, to|
        attributes.merge!(parsed_states: { from => to })
        transition = Transition.new(machine, attributes)
        name = attributes[:name]
        silent = attributes.fetch(:silent, false)

        machine.events_chain.add(name, transition)

        unless machine.respond_to?(name)
          event_definition.apply(name, silent)
        end
        state_definition.apply({ from => to })
      end
      self
    end
  end # TransitionBuilder
end # FiniteMachine
