# encoding: utf-8

module FiniteMachine
  # A class responsible for event notification
  class HookEvent
    include Threadable
    include Comparable

    MESSAGE = :trigger

    # HookEvent name
    attr_threadsafe :name

    # HookEvent type
    attr_threadsafe :type

    # Data associated with the event
    attr_threadsafe :data

    # Transition associated with the event
    attr_threadsafe :transition

    # Instantiate a new HookEvent object
    #
    # @param [Symbol] name
    #   The action or state name
    # @param [FiniteMachine::Transition]
    #   The transition associated with this event.
    # @param [Array[Object]] data
    #
    # @example
    #   HookEvent.new(:green, ...)
    #
    # @return [Object]
    #
    # @api public
    def initialize(name, transition, *data)
      @name       = name
      @transition = transition
      @data       = *data
      @type       = self.class
      freeze
    end

    # Build event hook
    #
    # @param [Symbol] :state
    #   The state name.
    # @param [FiniteMachine::Transition] :event_transition
    #   The transition associted with this hook.
    # @param [Array[Object]] :data
    #   The data associated with this hook
    #
    # @return [self]
    #
    # @api public
    def self.build(state, event_transition, *data)
      state_or_action = self < Anystate ? state : event_transition.name
      new(state_or_action, event_transition, *data)
    end

    # Notify subscriber about this event
    #
    # @return [nil]
    #
    # @api public
    def notify(subscriber, *args, &block)
      if subscriber.respond_to? MESSAGE
        subscriber.public_send(MESSAGE, self, *args, &block)
      end
    end

    class Anystate < HookEvent; end

    class Enter < Anystate; end

    class Transition < Anystate; end

    class Exit < Anystate; end

    class Anyaction < HookEvent; end

    class Before < Anyaction; end

    class After < Anyaction; end

    EVENTS = Anystate, Enter, Transition, Exit, Anyaction, Before, After

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
      [name, transition, data] <=> [other.name, other.transition, other.data]
    end
    alias_method :eql?, :==

    EVENTS.each do |event|
      (class << self; self; end).class_eval do
        define_method(event.event_name) { event }
      end
    end
  end # HookEvent
end # FiniteMachine
