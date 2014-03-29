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
      lambda { |*args, &block|  !call(*args, &block) }
    end

    # Execute action
    #
    # @param [Object] target
    #
    # @api public
    def call(target, *args, &block)
      case object
      when Symbol
        target.public_send(object.to_sym, *args, &block)
      when String
        string = args.empty? ? "-> { #{object} }" : "-> { #{object}(*#{args}) }"
        value  = eval string
        target.instance_exec(&value)
      when ::Proc
        object.arity.zero? ?  object.call : object.call(target, *args)
      else
        raise ArgumentError, "Unknown callable #{object}"
      end
    end
  end # Callable
end # FiniteMachine
