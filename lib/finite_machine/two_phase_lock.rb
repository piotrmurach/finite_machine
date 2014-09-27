# encoding: utf-8

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
      @sync ||= Sync.new
    end

    # Synchronize given block of code
    #
    # @param [Symbol] mode
    #   the synchronization mode out of :SH and :EX
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
