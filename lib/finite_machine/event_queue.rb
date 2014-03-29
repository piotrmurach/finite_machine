# encoding: utf-8

module FiniteMachine

  # A class responsible for running asynchronous events
  class EventQueue
    include Enumerable

    # Initialize an event queue
    #
    # @example
    #  EventQueue.new
    #
    # @api public
    def initialize
      @queue = Queue.new
      @mutex = Mutex.new
      @dead  = false
      run
    end

    # Retrieve the next event
    #
    # @return [AsyncCall]
    #
    # @api private
    def next_event
      @queue.pop
    end

    # Add asynchronous event to the event queue
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
      @mutex.lock
      begin
        @queue << event
      ensure
        @mutex.unlock rescue nil
      end
    end

    # Check if there are any events to handle
    #
    # @example
    #   event_queue.empty?
    #
    # @api public
    def empty?
      @queue.empty?
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
      !@dead
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
    def join(timeout)
      @thread.join timeout
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
      @mutex.lock
      begin
        @queue.clear
        @dead = true
      ensure
        @mutex.unlock rescue nil
      end
      true
    end

    private

    # Run all the events
    #
    # @return [Thread]
    #
    # @api private
    def run
      @thread = Thread.new do
        Thread.current.abort_on_exception = true
        until(@dead) do
          event = next_event
          Thread.exit unless event
          event.dispatch
        end
      end
    end
  end # EventQueue
end # FiniteMachine
