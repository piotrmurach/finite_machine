# frozen_string_literal: true

require "logger"

require_relative "finite_machine/const"
require_relative "finite_machine/logger"
require_relative "finite_machine/definition"
require_relative "finite_machine/state_machine"
require_relative "finite_machine/version"

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

  module ClassMethods
    attr_accessor :logger

    # Initialize an instance of finite machine
    #
    # @example
    #   FiniteMachine.new do
    #     ...
    #   end
    #
    # @return [FiniteMachine::StateMachine]
    #
    # @api public
    def new(*args, &block)
      StateMachine.new(*args, &block)
    end

    # A factory method for creating reusable FiniteMachine definitions
    #
    # @example
    #   TrafficLights = FiniteMachine.define
    #   lights_fm_a = TrafficLights.new
    #   lights_fm_b = TrafficLights.new
    #
    # @return [Class]
    #
    # @api public
    def define(&block)
      Class.new(Definition, &block)
    end
  end

  extend ClassMethods
end # FiniteMachine

FiniteMachine.logger = Logger.new(STDERR)
