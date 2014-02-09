# encoding: utf-8

module FiniteMachine

  # A class responsibile for storage of event subscribers
  class Subscribers
    include Enumerable

    def initialize(machine)
      @machine     = machine
      @subscribers = []
      @mutex       = Mutex.new
    end

    def each(&block)
      @subscribers.each(&block)
    end

    def index(subscriber)
      @subscribers.index(subscriber)
    end

    def empty?
      @subscribers.empty?
    end

    def subscribe(*observers)
      observers.each { |observer| @subscribers << observer }
    end

    def visit(event)
      each { |subscriber| @mutex.synchronize { event.notify subscriber } }
    end

    def reset
      @subscribers.clear
      self
    end

  end # Subscribers
end # FiniteMachine
