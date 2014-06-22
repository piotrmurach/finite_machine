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
      opts.merge!(parsed_states: { options[:from] => to })
      Transition.create(context.machine, opts)
    end
    alias_method :default, :choice
  end # ChoiceMerger
end # FiniteMachine
