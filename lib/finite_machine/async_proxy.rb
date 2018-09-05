# frozen_string_literal: true

require_relative 'callable'
require_relative 'message_queue'

module FiniteMachine
  # An asynchronous messages proxy
  #
  # @api private
  class AsyncProxy
    include Threadable

    attr_threadsafe :context

    # The queue for asynchronoous events
    #
    # @return [EventQueue]
    #
    # @api private
    attr_threadsafe :event_queue

    # Initialize an AsynxProxy
    #
    # @param [Object] context
    #   the context this proxy is associated with
    #
    # @api private
    def initialize(context)
      self.context     = context
      self.event_queue = MessageQueue.new

      ObjectSpace.define_finalizer(self, self.class.cleanup(event_queue))
    end

    # Delegate asynchronous event to event queue
    #
    # @api private
    def method_missing(method_name, *args, &block)
      callable   = Callable.new(method_name)
      async_call = AsyncCall.new(context, callable, *args, &block)

      event_queue.start unless event_queue.running?
      context.event_queue << async_call
    end

    # Clean up event queue
    #
    # @api private
    def self.cleanup(queue)
      proc do
        begin
          queue && queue.shutdown
        rescue MessageQueueDeadError
        end
      end
    end
  end # AsyncProxy
end # FiniteMachine
