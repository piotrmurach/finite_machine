# frozen_string_literal: true

require 'sync'

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
    def sync
      @sync = Sync.new
    end

    # Synchronize given block of code
    #
    # @param [Symbol] mode
    #   the lock mode out of :SH, :EX, :UN
    #
    # @return [nil]
    #
    # @api private
    def synchronize(mode, &block)
      sync.synchronize(mode, &block)
    end

    module_function :sync, :synchronize
  end # TwoPhaseLock
end # FiniteMachine
