# encoding: utf-8

module FiniteMachine
  # An asynchronous messages proxy
  class AsyncProxy

    attr_reader :context

    # Initialize an AsynxProxy
    #
    # @param [Object] context
    #   the context this proxy is associated with
    #
    # @api private
    def initialize(context)
      @context = context
    end

    # Delegate asynchronous event to event queue
    #
    # @api private
    def method_missing(method_name, *args, &block)
      @event_queue = FiniteMachine.event_queue
      @event_queue << AsyncCall.build(@context, Callable.new(method_name), *args, &block)
    end
  end # AsyncProxy
end # FiniteMachine
