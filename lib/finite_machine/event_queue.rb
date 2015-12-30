# encoding: utf-8

module FiniteMachine
  # A class responsible for running asynchronous events
  class EventQueue
    include Threadable

    # Initialize an event queue
    #
    # @example
    #  EventQueue.new
    #
    # @api public
    def initialize
      @queue     = Queue.new
      @dead      = false
      @listeners = []

      @thread = Thread.new do
        process_events
      end
    end

    # Retrieve the next event
    #
    # @return [AsyncCall]
    #
    # @api private
    def next_event
      sync_shared { @queue.pop }
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
      sync_exclusive { @queue << event }
      self
    end

    # Add listener to the queue to receive messages
    #
    # @api public
    def subscribe(*args, &block)
      sync_exclusive do
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
      sync_shared { @queue.empty? }
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
      sync_shared { !@dead }
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
      fail EventQueueDeadError, 'event queue already dead' if @dead

      queue = []
      sync_exclusive do
        queue = @queue
        @queue.clear
        @dead = true
      end
      while !queue.empty?
        Logger.debug "Discarded message: #{queue.pop}"
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
      sync_shared { @queue.size }
    end

    private

    # Notify consumers about process event
    #
    # @param [FiniteMachine::AsyncCall] event
    #
    # @api private
    def notify_listeners(event)
      sync_shared do
        @listeners.each { |listener| listener.handle_delivery(event) }
      end
    end

    # Process all the events
    #
    # @return [Thread]
    #
    # @api private
    def process_events
      until @dead
        event = next_event
        notify_listeners(event)
        event.dispatch
      end
    rescue Exception => ex
      Logger.error "Error while running event: #{Logger.format_error(ex)}"
    end
  end # EventQueue
end # FiniteMachine
