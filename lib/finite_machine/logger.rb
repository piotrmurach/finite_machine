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

    def format_error(error)
      message = "#{error.class}: #{error.message}\n\t"
      if error.backtrace
        message << "occured at #{error.backtrace.join("\n\t")}"
      else
        message << "EMPTY BACKTRACE\n\t"
      end
    end
  end # Logger
end # FiniteMachine
