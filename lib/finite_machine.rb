# frozen_string_literal: true

require 'logger'

require_relative 'finite_machine/const'
require_relative 'finite_machine/logger'
require_relative 'finite_machine/definition'
require_relative 'finite_machine/state_machine'
require_relative 'finite_machine/version'

module FiniteMachine
  # Default state name
  DEFAULT_STATE = :none

  # Initial default event name
  DEFAULT_EVENT_NAME = :init

  # Describe any transition state
  ANY_STATE = Const.new(:any)

  # Describe any event name
  ANY_EVENT = Const.new(:any_event)

  # When transition between states is invalid
  TransitionError = Class.new(::StandardError)

  # When failed to process callback
  CallbackError = Class.new(::StandardError)

  # Raised when transitioning to invalid state
  InvalidStateError = Class.new(::ArgumentError)

  InvalidEventError = Class.new(::NoMethodError)

  # Raised when a callback is defined with invalid name
  InvalidCallbackNameError = Class.new(::StandardError)

  # Raised when event has no transitions
  NotEnoughTransitionsError = Class.new(::ArgumentError)

  # Raised when initial event specified without state name
  MissingInitialStateError = Class.new(::StandardError)

  # Raised when event queue is already dead
  MessageQueueDeadError = Class.new(::StandardError)

  # Raised when argument is already defined
  AlreadyDefinedError = Class.new(::ArgumentError)

  class << self
    attr_accessor :logger

    # TODO: this should instantiate system not the state machine
    # and then delegate calls to StateMachine instance etc...
    #
    # @example
    #   FiniteMachine.define do
    #     ...
    #   end
    #
    # @return [FiniteMachine::StateMachine]
    #
    # @api public
    def define(*args, **options, &block)
      StateMachine.new(*args, **options, &block)
    end
    alias_method :new, :define
  end
end # FiniteMachine

FiniteMachine.logger = Logger.new(STDERR)
