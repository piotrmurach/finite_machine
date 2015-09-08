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

    def to_state(from)
      from
    end

    def ==(other)
      other.is_a?(UndefinedTransition) && name == other.name
    end

    protected

    attr_threadsafe :name

  end # UndefinedTransition
end # FiniteMachine
