# frozen_string_literal: true

require_relative 'listener'
require 'thread'

module FiniteMachine
  # Allows for storage of asynchronous messages such as events
  # and callbacks.
  #
  # Used internally by {Observer} and {StateMachine}
  #
  # @api private
  class MessageQueue
    # Initialize an event queue in separate thread
    #
    # @example
    #   MessageQueue.new
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
    # @api private
    def start
      return if running?
      @mutex.synchronize { spawn_thread }
    end

    # Spawn new background thread
    #
    # @api private
    def spawn_thread
      @thread = Thread.new do
        Thread.current.abort_on_exception = true
        process_events
      end
    end

    def running?
      !@thread.nil? && alive?
    end

    # Add asynchronous event to the event queue to process
    #
    # @example
    #   event_queue << AsyncCall.build(...)
    #
    # @param [AsyncCall] event
    #
    # @return [nil]
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

    # Add listener to the queue to receive messages
    #
    # @api public
    def subscribe(*args, &block)
      @mutex.synchronize do
        listener = Listener.new(*args)
        listener.on_delivery(&block)
        @listeners << listener
      end
    end

    # Check if there are any events to handle
    #
    # @example
    #   event_queue.empty?
    #
    # @api public
    def empty?
      @mutex.synchronize { @queue.empty? }
    end

    # Check if the event queue is alive
    #
    # @example
    #   event_queue.alive?
    #
    # @return [Boolean]
    #
    # @api public
    def alive?
      @mutex.synchronize { !@dead }
    end

    # Join the event queue from current thread
    #
    # @param [Fixnum] timeout
    #
    # @example
    #   event_queue.join
    #
    # @return [nil, Thread]
    #
    # @api public
    def join(timeout = nil)
      return unless @thread
      timeout.nil? ? @thread.join : @thread.join(timeout)
    end

    # Shut down this event queue and clean it up
    #
    # @example
    #   event_queue.shutdown
    #
    # @return [Boolean]
    #
    # @api public
    def shutdown
      fail EventQueueDeadError, 'event queue already dead' if @dead

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

    # Get number of events waiting for processing
    #
    # @example
    #   event_queue.size
    #
    # @return [Integer]
    #
    # @api public
    def size
      @mutex.synchronize { @queue.size }
    end

    def inspect
      @mutex.synchronize do
        "#<#{self.class}:#{object_id.to_s(16)} @size=#{size}, @dead=#{@dead}>"
      end
    end

    private

    # Notify consumers about process event
    #
    # @param [AsyncCall] event
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

    def discard_message(message)
      Logger.debug "Discarded message: #{message}" if $DEBUG
    end
  end # EventQueue
end # FiniteMachine
