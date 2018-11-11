# frozen_string_literal: true

require_relative 'choice_merger'
require_relative 'safety'
require_relative 'transition_builder'

module FiniteMachine
  # A generic DSL for describing the state machine
  class GenericDSL
    # Initialize a generic DSL
    #
    # @api public
    def initialize(machine, **attrs)
      @machine = machine
      @attrs   = attrs
    end

    # Expose any state constant
    # @api public
    def any_state
      ANY_STATE
    end

    # Expose any event constant
    # @api public
    def any_event
      ANY_EVENT
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
    include Safety

    # Initialize top level DSL
    #
    # @api public
    def initialize(machine, **attrs)
      super(machine, attrs)

      @machine.state = FiniteMachine::DEFAULT_STATE
      @defer_initial = true
      @silent_initial = true

      initial(@attrs[:initial])   if @attrs[:initial]
      terminal(@attrs[:terminal]) if @attrs[:terminal]
      log_transitions(@attrs.fetch(:log_transitions, false))
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
    def initial(value, **options)
      state = (value && !value.is_a?(Hash)) ? value : raise_missing_state
      name, @defer_initial, @silent_initial = *parse_initial(options)
      @initial_event = name
      event(name, FiniteMachine::DEFAULT_STATE => state, silent: @silent_initial)
    end

    # Trigger initial event
    #
    # @return [nil]
    #
    # @api private
    def trigger_init
      method = @silent_initial ? :transition : :trigger
      @machine.public_send(method, :"#{@initial_event}") unless @defer_initial
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

    # Create event and associate transition
    #
    # @example
    #   event :go, :green => :yellow
    #   event :go, :green => :yellow, if: :lights_on?
    #
    # @param [Symbol] name
    #   the event name
    # @param [Hash] transitions
    #   the event transitions and conditions
    #
    # @return [Transition]
    #
    # @api public
    def event(name, transitions = {}, &block)
      detect_event_conflict!(name) if machine.auto_methods?

      if block_given?
        merger = ChoiceMerger.new(machine, name, transitions)
        merger.instance_eval(&block)
      else
        transition_builder = TransitionBuilder.new(machine, name, transitions)
        transition_builder.call(transitions)
      end
    end

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

    # Decide whether to log transitions
    #
    # @api public
    def log_transitions(value)
      self.log_transitions = value
    end

    private

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
end # FiniteMachine
