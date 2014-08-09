# encoding: utf-8

module FiniteMachine
  # A class reponsible for building transition out of parsed states
  class TransitionBuilder
    include Threadable

    # The current state machine
    attr_threadsafe :machine

    attr_threadsafe :attributes

    # Initialize a TransitionBuilder
    #
    # @example
    #   TransitionBuilder.new(machine, {})
    #
    # @api public
    def initialize(machine, attributes = {})
      @machine = machine
      @attributes = attributes
    end

    # Creates transitions for the states
    #
    # @example
    #   transition_parser.call([:green, :yellow] => :red)
    #
    # @param [Hash[Symbol]] states
    #   The states to extract
    #
    # @return [nil]
    #
    # @api public
    def call(states)
      FiniteMachine::StateParser.new(states).parse_states do |from, to|
        attributes.merge!(parsed_states: { from => to })
        Transition.create(machine, attributes)
      end
    end
  end # TransitionBuilder
end # FiniteMachine
