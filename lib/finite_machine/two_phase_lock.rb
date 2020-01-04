# frozen_string_literal: true

require "concurrent/atomic/read_write_lock"

module FiniteMachine
  # Mixin to provide lock to a {Threadable}
  #
  # @api private
  module TwoPhaseLock
    # Create synchronization lock
    #
    # @return [Concurrent::ReadWriteLock]
    #
    # @api private
    def lock
      @lock = Concurrent::ReadWriteLock.new
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
      case mode
      when :EX
        lock.with_write_lock(&block)
      when :SH
        lock.with_read_lock(&block)
      end
    end
    module_function :synchronize
  end # TwoPhaseLock
end # FiniteMachine
