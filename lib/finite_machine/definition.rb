# frozen_string_literal: true

module FiniteMachine
  # Responsible for defining a standalone state machine
  #
  # @api public
  class Definition
    # The any event constant
    #
    # @example
    #   on_before(any_event) { ... }
    #
    # @return [FiniteMachine::Const]
    #
    # @api public
    def self.any_event
      ANY_EVENT
    end

    # The any state constant
    #
    # @example
    #   event :go, any_state => :green
    #
    # @example
    #   on_enter(any_state) { ... }
    #
    # @return [FiniteMachine::Const]
    #
    # @api public
    def self.any_state
      ANY_STATE
    end

    # Initialize a StateMachine
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
      FiniteMachine.new(*args) do
        context.deferreds.each { |d| d.call(self) }
      end
    end

    # Add deferred methods to the subclass
    #
    # @param [Class] subclass
    #   the inheriting subclass
    #
    # @return [void]
    #
    # @api private
    def self.inherited(subclass)
      super

      deferreds.each { |d| subclass.add_deferred(d) }
    end

    # The state machine deferreds
    #
    # @return [Array<Proc>]
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
    # @return [Array<Proc>]
    #
    # @api private
    def self.add_deferred(deferred)
      deferreds << deferred
    end

    # Delay lookup of DSL method
    #
    # @param [Symbol] method_name
    #   the method name
    # @param [Array] arguments
    #   the method arguments
    #
    # @return [void]
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
