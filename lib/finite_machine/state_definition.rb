# encoding: utf-8

module FiniteMachine
  # A class responsible for defining state query methods on state machine
  #
  # Used by {TranstionBuilder} to add state query definition
  # to the {StateMachine} instance.
  #
  # @api private
  class StateDefinition
    include Threadable

    # Initialize a StateDefinition
    #
    # @param [StateMachine] machine
    #
    # @api public
    def initialize(machine)
      self.machine = machine
    end

    # Define query methods for states
    #
    # @param [Hash] states
    #   the states that require query helpers
    #
    # @return [nil]
    #
    # @api public
    def apply(states)
      define_state_query_methods(states)
    end

    private

    # The current state machine
    attr_threadsafe :machine

    # Define helper state mehods for the transition states
    #
    # @param [Hash] states
    #   the states to define helpers for
    #
    # @return [nil]
    #
    # @api private
    def define_state_query_methods(states)
      states.to_a.flatten.each do |state|
        define_state_query_method(state)
      end
    end

    # Define state helper method
    #
    # @param [Symbol] state
    #   the state to define helper for
    #
    # @api private
    def define_state_query_method(state)
      return if machine.respond_to?("#{state}?")
      machine.send(:define_singleton_method, "#{state}?") do
        machine.is?(state.to_sym)
      end
    end
  end # StateDefinition
end # FiniteMachine
