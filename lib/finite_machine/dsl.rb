# encoding: utf-8

module FiniteMachine
  # A generic DSL for describing the state machine
  class GenericDSL
    # Initialize a generic DSL
    #
    # @api public
    def initialize(machine, attrs = {})
      @attrs = attrs
      @machine = machine
    end

    # Delegate attributes to machine instance
    #
    # @api private
    def method_missing(method_name, *args, &block)
      if @machine.respond_to?(method_name)
        @machine.send(method_name, *args, &block)
      else
        super
      end
    end

    # Configure state machine properties
    #
    # @api private
    def call(&block)
      instance_eval(&block)
    end
  end # GenericDSL

  # A class responsible for adding state machine specific dsl
  class DSL < GenericDSL
    # Initialize top level DSL
    #
    # @api public
    def initialize(machine, attrs = {})
      super(machine, attrs)

      @machine.state = FiniteMachine::DEFAULT_STATE
      @defer         = true

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
      name, @defer, silent = *parse_initial(options)
      @initial_event = name
      event(name, FiniteMachine::DEFAULT_STATE => state, silent: silent)
    end

    # Trigger initial event
    #
    # @return [nil]
    #
    # @api private
    def trigger_init
      public_send(:"#{@initial_event}") unless @defer
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
        env.target
      else
        env.target = object
      end
    end

    # Use alternative name for target
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
    #   the name to alias target to
    #
    # @return [FiniteMachine::StateMachine]
    #
    # @api public
    def alias_target(alias_name)
      env.aliases << alias_name.to_sym
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
      self.final_state = values
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
      events_dsl.call(&block)
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
      observer.call(&block)
    end

    # Error handler that throws exception when machine is in illegal state
    #
    # @api public
    def handlers(&block)
      errors_dsl.call(&block)
    end

    # Decide whether to log transitions
    #
    # @api public
    def log_transitions(value)
      self.log_transitions = value
    end

    private

    # Initialize state machine properties based off attributes
    #
    # @api private
    def initialize_attrs
      @attrs[:initial]  && initial(@attrs[:initial])
      @attrs[:target]   && target(@attrs[:target])
      @attrs[:terminal] && terminal(@attrs[:terminal])
      log_transitions(@attrs.fetch(:log_transitions, false))
    end

    # Parse initial options
    #
    # @param [Hash] options
    #   the options to extract for initial state setup
    #
    # @return [Array[Symbol,String]]
    #
    # @api private
    def parse_initial(options)
      [options.fetch(:event) { FiniteMachine::DEFAULT_EVENT_NAME },
       options.fetch(:defer) { false },
       options.fetch(:silent) { true }]
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
    include Safety
    # Create event and associate transition
    #
    # @example
    #   event :go, :green => :yellow
    #   event :go, :green => :yellow, if: :lights_on?
    #
    # @param [Symbol] name
    #   the event name
    # @param [Hash] attrs
    #   the event transitions and conditions
    #
    # @return [Transition]
    #
    # @api public
    def event(name, attrs = {}, &block)
      detect_event_conflict!(name)
      attributes = attrs.merge!(name: name)
      if block_given?
        merger = ChoiceMerger.new(@machine, attributes)
        merger.instance_eval(&block)
      else
        transition_builder = TransitionBuilder.new(@machine, attributes)
        transition_builder.call(attrs)
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
      @machine.handle(*exceptions, &block)
    end
  end # ErrorsDSL
end # FiniteMachine
