# encoding: utf-8

module FiniteMachine
  class UndefinedTransition
    include Threadable

    attr_threadsafe :event_name

    def initialize(event_name)
      self.event_name = event_name
    end

    def execute(*args)
      raise UndefinedError, "No transition for: #{event_name}"
    end

    def ==(other)
      other.is_a?(UndefinedTransition) && event_name == other.event_name
    end

    protected

    attr_threadsafe :name

  end # UndefinedTransition
end # FiniteMachine
