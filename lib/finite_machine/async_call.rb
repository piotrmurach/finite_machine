# encoding: utf-8

module FiniteMachine
  # An asynchronouse call representation
  #
  # Used internally by {EventQueue} to schedule events
  #
  # @api private
  class AsyncCall
    include Threadable

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
    # @return [self]
    #
    # @api public
    def initialize(context, callable, *args, &block)
      @context   = context
      @callable  = callable
      @arguments = args.dup
      @block     = block
      @mutex     = Mutex.new
      freeze
    end

    # Dispatch the event to the context
    #
    # @return [nil]
    #
    # @api private
    def dispatch
      @mutex.synchronize do
        callable.call(context, *arguments, &block)
      end
    end

    protected

    attr_threadsafe :context

    attr_threadsafe :callable

    attr_threadsafe :arguments

    attr_threadsafe :block
  end # AsyncCall
end # FiniteMachine
