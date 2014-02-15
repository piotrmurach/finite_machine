# encoding: utf-8

module FiniteMachine

  class GenericDSL
    class << self
      # @api private
      attr_accessor :top_level
    end

    def initialize(machine)
      @machine = machine
    end

    def method_missing(method_name, *args, &block)
      if @machine.respond_to?(method_name)
        @machine.send(method_name, *args, &block)
      else
        super
      end
    end

    def call(&block)
      instance_eval(&block)
      # top_level.instance_eval(&block)
    end
  end # GenericDSL

  class DSL < GenericDSL

    attr_reader :machine

    attr_reader :defer

    attr_reader :initial_event

    def initialize(machine)
      super(machine)
      machine.state = FiniteMachine::DEFAULT_STATE
      @defer = true
    end

    # Define initial state
    #
    # @params [String, Hash] value
    #
    # @api public
    def initial(value)
      if value.is_a?(String) || value.is_a?(Symbol)
        state, name = value, FiniteMachine::DEFAULT_EVENT_NAME
        @defer = false
      else
        state = value[:state]
        name  = value.has_key?(:event) ? value[:event] : FiniteMachine::DEFAULT_EVENT_NAME
        @defer = value[:defer] || true
      end
      @initial_event = name
      event = proc { event name, from: FiniteMachine::DEFAULT_STATE, to: state }
      machine.events.call(&event)
    end

    def target(value)
      machine.env.target = value
    end

    # Define terminal state
    #
    # @api public
    def terminal(value)
      machine.final_state = value
    end

    # Define state machine events
    #
    # @api public
    def events(&block)
      machine.events.call(&block)
    end

    # Define state machine callbacks
    #
    # @api public
    def callbacks(&block)
      machine.observer.call(&block)
    end

    # Error handler that throws exception when machine is in illegal state
    #
    # @api public
    def error
    end
  end # DSL

  class EventsDSL < GenericDSL

    attr_reader :machine

    def initialize(machine)
      super(machine)
    end

    # Create event and associate transition
    #
    # @example
    #   event :go, :green => :yellow
    #   event :go, :green => :yellow, if: :lights_on?
    #
    # @return [Transition]
    #
    # @api public
    def event(name, attrs = {}, &block)
      _transition = Transition.new(machine, attrs.merge!(name: name))
      _transition.define
      _transition.define_event
    end

  end # EventsDSL
end # FiniteMachine
