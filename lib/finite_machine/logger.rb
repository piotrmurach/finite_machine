# encoding: utf-8

module FiniteMachine
  module Logger
    module_function

    def debug(message)
      FiniteMachine.logger.debug(message)
    end

    def info(message)
      FiniteMachine.logger.info(message)
    end

    def warn(message)
      FiniteMachine.logger.warn(message)
    end

    def error(message)
      FiniteMachine.logger.error(message)
    end
  end # Logger
end # FiniteMachine
