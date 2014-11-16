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

    def report_transition(event_transition, *args)
      message = "Transition: @event=#{event_transition.name} "
      unless args.empty?
        message << "@with=[#{args.join(',')}] "
      end
      message << "#{event_transition.from_state} -> "
      message << "#{event_transition.machine.current}"
      info(message)
    end
  end # Logger
end # FiniteMachine
