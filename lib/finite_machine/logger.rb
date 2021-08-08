# frozen_string_literal: true

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
      message = ["#{error.class}: #{error.message}\n\t"]
      if error.backtrace
        message << "occured at #{error.backtrace.join("\n\t")}"
      else
        message << "EMPTY BACKTRACE\n\t"
      end
      message.join
    end

    def report_transition(machine_name, event_name, from, to, *args)
      message = ["Transition: @machine=#{machine_name} @event=#{event_name} "]
      unless args.empty?
        message << "@with=[#{args.join(',')}] "
      end
      message << "#{from} -> #{to}"
      info(message.join)
    end
  end # Logger
end # FiniteMachine
