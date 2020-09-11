# frozen_string_literal: true

require_relative "event_definition"
require_relative "state_definition"
require_relative "state_parser"
require_relative "transition"

module FiniteMachine
  # A class reponsible for building transition out of parsed states
  #
  # Used internally by {DSL} to
  #
  # @api private
  class TransitionBuilder
    # Initialize a TransitionBuilder
    #
    # @example
    #   TransitionBuilder.new(machine, {})
    #
    # @api public
    def initialize(machine, name, attributes = {})
      @machine    = machine
      @name       = name
      @attributes = attributes

      @event_definition = EventDefinition.new(machine)
      @state_definition = StateDefinition.new(machine)
    end

    # Converts user transitions into internal {Transition} representation
    #
    # @example
    #   transition_builder.call([:green, :yellow] => :red)
    #
    # @param [Hash[Symbol]] transitions
    #   The transitions to extract states from
    #
    # @return [self]
    #
    # @api public
    def call(transitions)
      StateParser.parse(transitions) do |from, to|
        transition = Transition.new(@machine.env.target, @name,
                                    @attributes.merge(states: { from => to }))
        silent = @attributes.fetch(:silent, false)
        @machine.events_map.add(@name, transition)
        next unless @machine.auto_methods?

        unless @machine.respond_to?(@name)
          @event_definition.apply(@name, silent)
        end
        @state_definition.apply(from => to)
      end
      self
    end
  end # TransitionBuilder
end # FiniteMachine
