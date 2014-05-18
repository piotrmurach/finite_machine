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

    attr_threadsafe :attrs

    # Initialize a generic DSL
    #
    # @api public
    def initialize(machine, attrs = {})
      self.attrs = attrs
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

  # A class responsible for adding state machine specific dsl
  class DSL < GenericDSL
    attr_threadsafe :defer

    attr_threadsafe :initial_event

    # Initialize top level DSL
    #
    # @api public
    def initialize(machine, attrs = {})
      super(machine, attrs)
      machine.state = FiniteMachine::DEFAULT_STATE
      self.defer    = true

      initialize_attrs
    end

    # Define initial state
    #
    # @example
    #   initial :green
    #
    # @example
    #   initial state: green, defer: true
    #
    # @param [String, Hash] value
    #
    # @return [StateMachine]
    #
    # @api public
    def initial(value)
      state, name, self.defer = parse(value)
      unless defer
        machine.state         = state
        machine.initial_state = state
      end
      event = proc { event name, from: FiniteMachine::DEFAULT_STATE, to: state }
      machine.events_dsl.call(&event)
    end

    # Attach state machine to an object
    #
    # This allows state machine to initiate events in the context
    # of a particular object
    #
    # @example
    #   FiniteMachine.define do
    #     target :red
    #  end
    #
    # @param [Object] object
    #
    # @return [FiniteMachine::StateMachine]
    #
    # @api public
    def target(object = nil)
      if object.nil?
        machine.env.target
      else
        machine.env.target = object
      end
    end

    # Define terminal state
    #
    # @example
    #   terminal :red
    #
    # @return [FiniteMachine::StateMachine]
    #
    # @api public
    def terminal(value)
      machine.final_state = value
    end

    # Define state machine events
    #
    # @return [FiniteMachine::StateMachine]
    #
    # @api public
    def events(&block)
      machine.events_dsl.call(&block)
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

    # Initialize state machine properties based off attributes
    #
    # @api private
    def initialize_attrs
      attrs[:initial]  and initial(attrs[:initial])
      attrs[:target]   and target(attrs[:target])
      attrs[:terminal] and terminal(attrs[:terminal])
    end

    # Parse initial options
    #
    # @param [Object] value
    #
    # @return [Array[Symbol,String]]
    #
    # @api private
    def parse(value)
      unless value.is_a?(Hash)
        [value, FiniteMachine::DEFAULT_EVENT_NAME, false]
      else
        [value.fetch(:state) { raise_missing_state },
         value.fetch(:event) { FiniteMachine::DEFAULT_EVENT_NAME },
         value.fetch(:defer) { false }]
      end
    end

    # Raises missing state error
    #
    # @api private
    def raise_missing_state
      raise MissingInitialStateError,
            'Provide state to transition :to for the initial event'
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
        _transition.define_state_methods
        _transition.define_event
      end
    end
  end # EventsDSL

  class ErrorsDSL < GenericDSL

    # Add error handler
    #
    # @param [Array] exceptions
    #
    # @example
    #   handle InvalidStateError, with: :log_errors
    #
    # @return [Array[Exception]]
    #
    # @api public
    def handle(*exceptions, &block)
      machine.handle(*exceptions, &block)
    end
  end # ErrorsDSL
end # FiniteMachine
