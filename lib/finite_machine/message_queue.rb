# frozen_string_literal: true

require_relative "listener"
require "thread"

module FiniteMachine
  # Responsible for storage of asynchronous messages such as events
  # and callbacks.
  #
  # Used internally by {Observer}
  #
  # @api private
  class MessageQueue
    # Initialize a MessageQueue
    #
    # @example
    #   message_queue = FiniteMachine::MessageQueue.new
    #
    # @api public
    def initialize
      @not_empty = ConditionVariable.new
      @mutex     = Mutex.new
      @queue     = Queue.new
      @dead      = false
      @listeners = []
      @thread    = nil
    end

    # Start a new thread with a queue of callback events to run
    #
    # @example
    #   message_queue.start
    #
    # @return [Thread, nil]
    #
    # @api private
    def start
      return if running?

      @mutex.synchronize { spawn_thread }
    end

    # Spawn a new background thread
    #
    # @return [Thread]
    #
    # @api private
    def spawn_thread
      @thread = Thread.new do
        Thread.current.abort_on_exception = true
        process_events
      end
    end

    # Check whether or not the message queue is running
    #
    # @example
    #   message_queue.running?
    #
    # @return [Boolean]
    #
    # @api public
    def running?
      !@thread.nil? && alive?
    end

    # Add an asynchronous event to the message queue to process
    #
    # @example
    #   message_queue << AsyncCall.build(...)
    #
    # @param [FiniteMachine::AsyncCall] event
    #   the event to add
    #
    # @return [void]
    #
    # @api public
    def <<(event)
      @mutex.synchronize do
        if @dead
          discard_message(event)
        else
          @queue << event
          @not_empty.signal
        end
      end
    end

    # Add a listener for the message queue to receive notifications
    #
    # @example
    #   message_queue.subscribe { |event| ... }
    #
    # @return [void]
    #
    # @api public
    def subscribe(*args, &block)
      @mutex.synchronize do
        listener = Listener.new(*args)
        listener.on_delivery(&block)
        @listeners << listener
      end
    end

    # Check whether or not there are any messages to handle
    #
    # @example
    #   message_queue.empty?
    #
    # @api public
    def empty?
      @mutex.synchronize { @queue.empty? }
    end

    # Check whether or not the message queue is alive
    #
    # @example
    #   message_queue.alive?
    #
    # @return [Boolean]
    #
    # @api public
    def alive?
      @mutex.synchronize { !@dead }
    end

    # Join the message queue from the current thread
    #
    # @param [Fixnum] timeout
    #   the time limit
    #
    # @example
    #   message_queue.join
    #
    # @return [Thread, nil]
    #
    # @api public
    def join(timeout = nil)
      return unless @thread

      timeout.nil? ? @thread.join : @thread.join(timeout)
    end

    # Shut down this message queue and clean it up
    #
    # @example
    #   message_queue.shutdown
    #
    # @raise [FiniteMachine::MessageQueueDeadError]
    #
    # @return [Boolean]
    #
    # @api public
    def shutdown
      raise MessageQueueDeadError, "message queue already dead" if @dead

      queue = []
      @mutex.synchronize do
        @dead = true
        @not_empty.broadcast

        queue = @queue
        @queue.clear
      end
      while !queue.empty?
        discard_message(queue.pop)
      end
      true
    end

    # The number of messages waiting for processing
    #
    # @example
    #   message_queue.size
    #
    # @return [Integer]
    #
    # @api public
    def size
      @mutex.synchronize { @queue.size }
    end

    # Inspect this message queue
    #
    # @example
    #   message_queue.inspect
    #
    # @return [String]
    #
    # @api public
    def inspect
      @mutex.synchronize do
        "#<#{self.class}:#{object_id.to_s(16)} @size=#{size}, @dead=#{@dead}>"
      end
    end

    private

    # Notify listeners about the event
    #
    # @param [FiniteMachine::AsyncCall] event
    #   the event to notify listeners about
    #
    # @return [void]
    #
    # @api private
    def notify_listeners(event)
      @listeners.each { |listener| listener.handle_delivery(event) }
    end

    # Process all the events
    #
    # @return [Thread]
    #
    # @api private
    def process_events
      until @dead
        @mutex.synchronize do
          while @queue.empty?
            @not_empty.wait(@mutex)
          end
          event = @queue.pop
          break unless event

          notify_listeners(event)
          event.dispatch
        end
      end
    rescue Exception => ex
      Logger.error "Error while running event: #{Logger.format_error(ex)}"
    end

    # Log discarded message
    #
    # @param [FiniteMachine::AsyncCall] message
    #   the message to discard
    #
    # @return [void]
    #
    # @api private
    def discard_message(message)
      Logger.debug "Discarded message: #{message}" if $DEBUG
    end
  end # EventQueue
end # FiniteMachine
