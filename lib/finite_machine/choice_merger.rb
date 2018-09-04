# frozen_string_literal: true

module FiniteMachine
  # A class responsible for merging choice options
  class ChoiceMerger
    include Threadable

    # The context where choice is executed
    attr_threadsafe :machine

    # The options passed in to the machine
    attr_threadsafe :options

    # Initialize a ChoiceMerger
    #
    # @api private
    def initialize(machine, options)
      self.machine = machine
      self.options = options
    end

    # Create choice transition
    #
    # @example
    #   event from: :green do
    #     choice :yellow
    #   end
    #
    # @param [Symbol] to
    #   the to state
    # @param [Hash] attrs
    #
    # @return [FiniteMachine::Transition]
    #
    # @api public
    def choice(to, attrs = {})
      opts = options.dup
      opts.merge!(attrs)
      transition_builder = TransitionBuilder.new(machine, opts)
      transition_builder.call(options[:from] => to)
    end
    alias_method :default, :choice
  end # ChoiceMerger
end # FiniteMachine
