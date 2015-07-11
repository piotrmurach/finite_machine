# encoding: utf-8

module FiniteMachine
  # A class responsible for event notification
  class HookEvent
    include Threadable
    include Comparable

    class Anystate < HookEvent; end

    class Enter < Anystate; end

    class Transition < Anystate; end

    class Exit < Anystate; end

    class Anyaction < HookEvent; end

    class Before < Anyaction; end

    class After < Anyaction; end

    EVENTS = Anystate, Enter, Transition, Exit, Anyaction, Before, After

    TRIGGER_MESSAGE = :trigger

    # HookEvent name
    attr_threadsafe :name

    # HookEvent type
    attr_threadsafe :type

    # Transition associated with the event
    attr_threadsafe :transition

    # Instantiate a new HookEvent object
    #
    # @param [Symbol] name
    #   The action or state name
    # @param [FiniteMachine::Transition]
    #   The transition associated with this event.
    #
    # @example
    #   HookEvent.new(:green, ...)
    #
    # @return [self]
    #
    # @api public
    def initialize(name, transition)
      @name       = name
      @type       = self.class
      @transition = transition
      freeze
    end

    # Build event hook
    #
    # @param [Symbol] :state
    #   The state name.
    # @param [FiniteMachine::Transition] :event_transition
    #   The transition associted with this hook.
    #
    # @return [self]
    #
    # @api public
    def self.build(state, event_transition)
      state_or_action = self < Anystate ? state : event_transition.name
      new(state_or_action, event_transition)
    end

    # Notify subscriber about this event
    #
    # @param [Observer] subscriber
    #   the object subscribed to be notified about this event
    #
    # @param [Array] data
    #   the data associated with the triggered event
    #
    # @return [nil]
    #
    # @api public
    def notify(subscriber, *data)
      if subscriber.respond_to?(TRIGGER_MESSAGE)
        subscriber.public_send(TRIGGER_MESSAGE, self, *data)
      end
    end

    # Extract event name
    #
    # @return [String] the event name
    #
    # @api public
    def self.event_name
      name.split('::').last.downcase.to_sym
    end

    # String representation
    #
    # @return [String] the event name
    #
    # @api public
    def self.to_s
      event_name.to_s
    end

    # Compare whether the instance is greater, less then or equal to other
    #
    # @return [-1 0 1]
    #
    # @api public
    def <=>(other)
      other.is_a?(type) &&
      [name, transition] <=> [other.name, other.transition]
    end
    alias_method :eql?, :==

    EVENTS.each do |event|
      (class << self; self; end).class_eval do
        define_method(event.event_name) { event }
      end
    end
  end # HookEvent
end # FiniteMachine
