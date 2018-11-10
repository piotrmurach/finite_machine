# frozen_string_literal: true

module FiniteMachine
  # An immutable asynchronouse call representation that wraps
  # the {Callable} object
  #
  # Used internally by {MessageQueue} to dispatch events
  #
  # @api private
  class AsyncCall
    # Create asynchronous call instance
    #
    # @param [Object] context
    # @param [Callable] callable
    # @param [Array] args
    # @param [#call] block
    #
    # @example
    #   AsyncCall.new(context, Callable.new(:method), :a, :b)
    #
    # @api public
    def initialize(context, callable, *args, &block)
      @context   = context
      @callable  = callable
      @arguments = args.dup
      @block     = block
      freeze
    end

    # Dispatch the event to the context
    #
    # @return [nil]
    #
    # @api private
    def dispatch
      @callable.call(@context, *@arguments, &@block)
    end
  end # AsyncCall
end # FiniteMachine
