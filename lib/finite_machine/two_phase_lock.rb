
module FiniteMachine
  module TwoPhaseLock     
    def sync
      @sync ||= Sync.new
    end

    def synchronize(mode, &block)
      sync.synchronize(mode, &block)
    end

    module_function :sync, :synchronize
  end
end
