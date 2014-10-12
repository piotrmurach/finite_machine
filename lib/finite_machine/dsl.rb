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
    # @param [Symbol] value
    #   The initial state name.
    # @param [Hash[Symbol]] options
    # @option options [Symbol] :event
    #   The event name.
    # @option options [Symbol] :defer
    #   Set to true to defer initial state transition.
    #   Default false.
    # @option options [Symbol] :silent
    #   Set to true to disable callbacks.
    #   Default true.
    #
    # @example
    #   initial :green
    #
    # @example Defer initial event
    #   initial state: green, defer: true
    #
    # @example Trigger callbacks
    #   initial :green, silent: false
    #
    # @example Redefine event name
    #   initial :green, event: :start
    #
    # @param [String, Hash] value
    #
    # @return [StateMachine]
    #
    # @api public
    def initial(value, options = {})
      state = (value && !value.is_a?(Hash)) ? value : raise_missing_state
      name, self.defer, silent = parse(options)
      self.initial_event = name
      machine.event(name, FiniteMachine::DEFAULT_STATE => state, silent: silent)
    end

    # Trigger initial event
    #
    # @return [nil]
    #
    # @api private
    def trigger_init
      machine.send(:"#{initial_event}") unless defer
    end

    # Attach state machine to an object
    #
    # This allows state machine to initiate events in the context
    # of a particular object
    #
    # @example
    #   FiniteMachine.define do
    #     target :red
    #   end
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
    
    # Use alternative name for target within definition
    # 
    # @example
    #   target_alias: :car
    #   
    #   callbacks {
    #     on_transition do |event|
    #       car.state = event.to
    #     end
    #   }
    # 
    # @param [Symbol] alias_name
    #
    # @api public
    def target_alias(alias_name)
      FiniteMachine::StateMachine.send(:alias_method, alias_name, :target)
    end

    # Define terminal state
    #
    # @example
    #   terminal :red
    #
    # @return [FiniteMachine::StateMachine]
    #
    # @api public
    def terminal(*values)
      machine.final_state = values
    end

    # Define state machine events
    #
    # @example
    #   events do
    #     event :start, :red => :green
    #   end
    #
    # @return [FiniteMachine::StateMachine]
    #
    # @api public
    def events(&block)
      machine.events_dsl.call(&block)
    end

    # Define state machine callbacks
    #
    # @example
    #   callbacks do
    #     on_enter :green do |event| ... end
    #   end
    #
    # @return [FiniteMachine::Observer]
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
      if value.is_a?(Hash)
        [value.fetch(:event) { FiniteMachine::DEFAULT_EVENT_NAME },
         value.fetch(:defer) { false },
         value.fetch(:silent) { true }]
      else
        [FiniteMachine::DEFAULT_EVENT_NAME, false, true]
      end
    end

    # Raises missing state error
    #
    # @raise [MissingInitialStateError]
    #   Raised when state name is not provided for initial.
    #
    # @return [nil]
    #
    # @api private
    def raise_missing_state
      fail MissingInitialStateError,
           'Provide state to transition :to for the initial event'
    end
  end # DSL

  # A DSL for describing events
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
        attributes = attrs.merge!(name: name)
        if block_given?
          merger = ChoiceMerger.new(self, attributes)
          merger.instance_eval(&block)
        else
          transition_builder = TransitionBuilder.new(machine, attributes)
          transition_builder.call(attrs)
        end
      end
    end
  end # EventsDSL

  # A DSL for describing error conditions
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
