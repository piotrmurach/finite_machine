# encoding: utf-8

require "thread"
require "sync"

require "finite_machine/version"
require "finite_machine/threadable"
require "finite_machine/callable"
require "finite_machine/catchable"
require "finite_machine/async_proxy"
require "finite_machine/async_call"
require "finite_machine/event"
require "finite_machine/hooks"
require "finite_machine/transition"
require "finite_machine/dsl"
require "finite_machine/state_machine"
require "finite_machine/subscribers"
require "finite_machine/observer"

module FiniteMachine

  DEFAULT_STATE = :none

  DEFAULT_EVENT_NAME = :init

  ANY_STATE = :any

  ANY_EVENT = :any

  ANY_STATE_HOOK = :state

  ANY_EVENT_HOOK = :event

  # Returned when transition has successfully performed
  SUCCEEDED = 1

  # Returned when transition is cancelled in callback
  CANCELLED = 2

  # Returned when transition has not changed the state
  NOTRANSITION = 3

  # When transition between states is invalid
  TransitionError = Class.new(::StandardError)

  # Raised when transitining to invalid state
  InvalidStateError = Class.new(::ArgumentError)

  InvalidEventError = Class.new(::NoMethodError)

  # Raised when a callback is defined with invalid name
  InvalidCallbackNameError = Class.new(::StandardError)

  # Raised when event has no transitions
  NotEnoughTransitionsError = Class.new(::ArgumentError)

  Environment = Struct.new(:target)

  # TODO: this should instantiate system not the state machine
  # and then delegate calls to StateMachine instance etc...
  def self.define(*args, &block)
    StateMachine.new(*args, &block)
  end

end # FiniteMachine
