# encoding: utf-8

module FiniteMachine
  # A mixin to allow sharing of thread context
  module ThreadContext

    # @api public
    def event_queue
      Thread.current[:finite_machine_event_queue]
    end

    # @api public
    def event_queue=(value)
      Thread.current[:finite_machine_event_queue] = value
    end
  end # ThreadContext
end # FiniteMachine
