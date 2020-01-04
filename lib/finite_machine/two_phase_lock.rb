# frozen_string_literal: true

require "sync"

module FiniteMachine
  # Mixin to provide lock to a {Threadable}
  #
  # @api private
  module TwoPhaseLock
    # Create synchronization lock
    #
    # @return [Sync]
    #
    # @api private
    def lock
      @lock = Sync.new
    end
    module_function :lock

    # Synchronize given block of code
    #
    # @param [Symbol] mode
    #   the lock mode out of :SH, :EX, :UN
    #
    # @return [nil]
    #
    # @api private
    def synchronize(mode, &block)
      lock.synchronize(mode, &block)
    end
    module_function :synchronize
  end # TwoPhaseLock
end # FiniteMachine
