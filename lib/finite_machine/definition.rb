# encoding: utf-8

module FiniteMachine
  # A class responsible for defining standalone state machine
  class Definition
    # The machine deferreds
    #
    # @return [Array[Proc]]
    #
    # @api private
    def self.deferreds
      @deferreds ||= []
    end

    # Add deferred
    #
    # @param [Proc] deferred
    #   the deferred execution
    #
    # @return [Array[Proc]]
    #
    # @api private
    def self.add_deferred(deferred)
      deferreds << deferred
    end

    # Instantiate a new Definition
    #
    # @example
    #   class Engine < FiniteMachine::Definition
    #     ...
    #   end
    #
    #   engine = Engine.new
    #
    # @return [FiniteMachine::StateMachine]
    #
    # @api public
    def self.new(*args)
      context = self
      FiniteMachine.define(*args) do
        context.deferreds.each { |d| d.call(self) }
      end
    end

    # Set deferrerd methods on the subclass
    #
    # @api private
    def self.inherited(subclass)
      super

      self.deferreds.each { |d| subclass.add_deferred(d) }
    end

    # Delay lookup of DSL method
    #
    # @param [Symbol] method_name
    #
    # @return [nil]
    #
    # @api private
    def self.method_missing(method_name, *arguments, &block)
      deferred = proc do |name, args, blok, object|
        object.send(name, *args, &blok)
      end
      deferred = deferred.curry(4)[method_name][arguments][block]
      add_deferred(deferred)
    end
  end # Definition
end # FiniteMachine
