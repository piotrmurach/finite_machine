# encoding: utf-8

module FiniteMachine
  class UndefinedTransition
    include Threadable

    def initialize(name)
      self.name = name
    end

    def cancelled?
      false
    end

    def silent?
      false
    end

    def same?(_)
      false
    end

    def current?
      false
    end

    def execute(*args)
      raise UndefinedError, "No transition for: #{name}"
    end

    def ==(other)
      other.is_a?(UndefinedTransition) && name == other.name
    end

    protected

    attr_threadsafe :name

  end # UndefinedTransition
end # FiniteMachine
