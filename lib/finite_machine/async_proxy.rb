# encoding: utf-8

module FiniteMachine
  # An asynchronous messages proxy
  class AsyncProxy
    include Threadable
    include ThreadContext

    attr_threadsafe :context

    # Initialize an AsynxProxy
    #
    # @param [Object] context
    #   the context this proxy is associated with
    #
    # @api private
    def initialize(context)
      self.context = context
    end

    # Delegate asynchronous event to event queue
    #
    # @api private
    def method_missing(method_name, *args, &block)
      callable   = Callable.new(method_name)
      async_call = AsyncCall.new(context, callable, *args, &block)

      event_queue << async_call
    end
  end # AsyncProxy
end # FiniteMachine
