# frozen_string_literal: true

module FiniteMachine
  # Holds references to targets and aliases
  #
  # @api public
  class Env
    include Threadable

    attr_threadsafe :target

    attr_threadsafe :aliases

    def initialize(target, aliases)
      @target = target
      @aliases = aliases
    end
  end # Env
end # FiniteMachine
