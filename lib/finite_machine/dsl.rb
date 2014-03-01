# encoding: utf-8

module FiniteMachine

  # A generic DSL for describing the state machine
  class GenericDSL
    include Threadable

    class << self
      # @api private
      attr_accessor :top_level
    end

    attr_threadsafe :machine

    def initialize(machine)
      self.machine = machine
    end

    def method_missing(method_name, *args, &block)
      if @machine.respond_to?(method_name)
        @machine.send(method_name, *args, &block)
      else
        super
      end
    end

    def call(&block)
      sync_exclusive { instance_eval(&block) }
      # top_level.instance_eval(&block)
    end
  end # GenericDSL

  class DSL < GenericDSL

    attr_threadsafe :defer

    attr_threadsafe :initial_event

    # Initialize top level DSL
    #
    # @api public
    def initialize(machine)
      super(machine)
      machine.state = FiniteMachine::DEFAULT_STATE
      self.defer = true
    end

    # Define initial state
    #
    # @params [String, Hash] value
    #
    # @api public
    def initial(value)
      state, name, self.defer = parse(value)
      self.initial_event = name
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
    def handlers(&block)
      machine.errors.call(&block)
    end

    private

    # Parse initial options
    #
    # @params [String, Hash] value
    #
    # @return [Array[Symbol,String]]
    #
    # @api private
    def parse(value)
      if value.is_a?(String) || value.is_a?(Symbol)
        [value, FiniteMachine::DEFAULT_EVENT_NAME, false]
      else
        [value[:state], value.fetch(:event, FiniteMachine::DEFAULT_EVENT_NAME),
        !!value[:defer]]
      end
    end
  end # DSL

  class EventsDSL < GenericDSL

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
      sync_exclusive do
        _transition = Transition.new(machine, attrs.merge!(name: name))
        _transition.define
        _transition.define_event
      end
    end
  end # EventsDSL

  class ErrorsDSL < GenericDSL

    def initialize(machine)
      super(machine)
      machine.error_handlers = []
    end

    # Add error handler
    #
    # @param [Array] exceptions
    #
    # @api public
    def handle(*exceptions, &block)
      machine.handle(*exceptions, &block)
    end

  end # ErrorsDSL
end # FiniteMachine
