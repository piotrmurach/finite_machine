# encoding: utf-8

module FiniteMachine

  # A generic interface for executing strings, symbol methods or procs.
  class Callable

    attr_reader :object

    # Initialize a Callable
    #
    # @param [Symbol, String, Proc] object
    #   the callable object
    #
    # @api public
    def initialize(object)
      @object = object
    end

    # Invert callable
    #
    # @api public
    def invert
      lambda { |*args, &block|  !self.call(*args, &block) }
    end

    # Execute action
    #
    # @param [Object] target
    #
    # @api public
    def call(env, *args, &block)
      target = env.target
      case object
      when Symbol
        target.__send__(@object.to_sym)
      when String
        value = eval "lambda { #{@object} }"
        target.instance_exec(&value)
      when ::Proc
        if object.arity >= 1
          object.call(target, *args)
        else
          object.call
        end
      else
        raise ArgumentError, "Unknown callable #{@object}"
      end
    end
  end # Callable
end # FiniteMachine
