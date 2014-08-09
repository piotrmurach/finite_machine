# encoding: utf-8

module FiniteMachine
  # A class responsible for merging choice options
  class ChoiceMerger
    include Threadable

    # The context where choice is executed
    attr_threadsafe :context

    # The options passed in to the context
    attr_threadsafe :options

    # Initialize a ChoiceMerger
    #
    # @api private
    def initialize(context, options)
      self.context = context
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
      transition_builder = TransitionBuilder.new(context.machine, opts)
      transition_builder.call(options[:from] => to)
    end
    alias_method :default, :choice
  end # ChoiceMerger
end # FiniteMachine
