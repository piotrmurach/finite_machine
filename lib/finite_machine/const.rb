# frozen_string_literal: true

module FiniteMachine
  class Const
    def initialize(name)
      @name = name.to_s
      freeze
    end

    def to_s
      @name
    end
    alias to_str to_s
    alias inspect to_s
  end # Const
end # FiniteMachine
