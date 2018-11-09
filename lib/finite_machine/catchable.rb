# frozen_string_literal: true

module FiniteMachine
  # A mixin to allow for specifying error handlers
  module Catchable
    # Extends object with error handling methods
    #
    # @api private
    def self.included(base)
      base.module_eval do
        attr_threadsafe :error_handlers, default: []
      end
    end

    # Rescue exception raised in state machine
    #
    # @param [Array[Exception]] exceptions
    #
    # @example
    #   handle TransitionError, with: :pretty_errors
    #
    # @example
    #   handle TransitionError do |exception|
    #     logger.info exception.message
    #     raise exception
    #   end
    #
    # @api public
    def handle(*exceptions, &block)
      options = exceptions.last.is_a?(Hash) ? exceptions.pop : {}

      unless options.key?(:with)
        if block_given?
          options[:with] = block
        else
          raise ArgumentError, 'Need to provide error handler.'
        end
      end
      evaluate_exceptions(exceptions, options)
    end

    # Catches error and finds a handler
    #
    # @param [Exception] exception
    #
    # @return [Boolean]
    #   true if handler is found, nil otherwise
    #
    # @api public
    def catch_error(exception)
      if handler = handler_for_error(exception)
        handler.arity.zero? ? handler.call : handler.call(exception)
        true
      end
    end

    private

    def handler_for_error(exception)
      _, handler = error_handlers.reverse.find do |class_name, _|
        klass = FiniteMachine.const_get(class_name) rescue nil
        klass ||= extract_const(class_name)
        exception <= klass
      end
      evaluate_handler(handler)
    end

    # Find constant in state machine namespace
    #
    # @param [String] class_name
    #
    # @api private
    def extract_const(class_name)
      class_name.split('::').reduce(FiniteMachine) do |constant, part|
        constant.const_get(part)
      end
    end

    # Executes given handler
    #
    # @api private
    def evaluate_handler(handler)
      case handler
      when Symbol
        target.method(handler)
      when Proc
        if handler.arity.zero?
          proc { instance_exec(&handler) }
        else
          proc { |_exception| instance_exec(_exception, &handler) }
        end
      end
    end

    # Check if exception inherits from Exception class and add to error handlers
    #
    # @param [Array[Exception]] exceptions
    #
    # @param [Hash] options
    #
    # @api private
    def evaluate_exceptions(exceptions, options)
      exceptions.each do |exception|
        key = if exception.is_a?(Class) && exception <= Exception
          exception.name
        elsif exception.is_a?(String)
          exception
        else
          raise ArgumentError, "#{exception} isn't an Exception"
        end

        error_handlers << [key, options[:with]]
      end
    end
  end # Catchable
end # FiniteMachine
