# encoding: utf-8

module FiniteMachine
  # An asynchronouse call representation
  class AsyncCall
    include Threadable

    attr_threadsafe :context

    attr_threadsafe :callable

    attr_threadsafe :arguments

    attr_threadsafe :block

    # Create an AsynCall
    #
    # @api private
    def initialize
      @mutex = Mutex.new
    end

    # Build asynchronous call instance
    #
    # @param [Object] context
    # @param [Callable] callable
    # @param [Array] args
    # @param [#call] block
    #
    # @example
    #   AsyncCall.build(self, Callable.new(:method), :a, :b)
    #
    # @return [self]
    #
    # @api public
    def self.build(context, callable, *args, &block)
      instance = new
      instance.context = context
      instance.callable = callable
      instance.arguments = args
      instance.block = block
      instance
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
  end # AsyncCall
end # FiniteMachine
