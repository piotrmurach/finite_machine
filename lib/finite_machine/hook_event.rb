# frozen_string_literal: true

module FiniteMachine
  # A class responsible for event notification
  class HookEvent
    include Comparable

    class Anystate < HookEvent; end

    class Enter < Anystate; end

    class Transition < Anystate; end

    class Exit < Anystate; end

    class Anyaction < HookEvent; end

    class Before < Anyaction; end

    class After < Anyaction; end

    EVENTS = Anystate, Enter, Transition, Exit, Anyaction, Before, After

    MESSAGE = :emit

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

    # Choose any state or event name based on even type
    #
    # @param [HookEvent] event_type
    #
    # @return [Symbol]
    #   out of :any or :any_event
    #
    # @api public
    def self.any_state_or_event(event_type)
      event_type < Anyaction ? ANY_EVENT : ANY_STATE
    end

    # Build event hook
    #
    # @param [Symbol] :state
    #   The state or action name.
    #
    # @param [Symbol] :event_name
    #   The event name associted with this hook.
    #
    # @return [self]
    #
    # @api public
    def self.build(state, event_name, from)
      state_or_action = self < Anystate ? state : event_name
      new(state_or_action, event_name, from)
    end

    EVENTS.each do |event|
      (class << self; self; end).class_eval do
        define_method(event.event_name) { event }
      end
    end

    # HookEvent state or action name
    attr_reader :name

    # HookEvent type
    attr_reader :type

    # The from state this hook has been fired
    attr_reader :from

    # The event name triggering this hook event
    attr_reader :event_name

    # Instantiate a new HookEvent object
    #
    # @param [Symbol] name
    #   The action or state name
    #
    # @param [Symbol] event_name
    #   The event name associated with this hook event.
    #
    # @example
    #   HookEvent.new(:green, :move, :green)
    #
    # @return [self]
    #
    # @api public
    def initialize(name, event_name, from)
      @name       = name
      @type       = self.class
      @event_name = event_name
      @from       = from
      freeze
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
      return unless subscriber.respond_to?(MESSAGE)

      subscriber.public_send(MESSAGE, self, *data)
    end

    # Compare whether the instance is greater, less then or equal to other
    #
    # @return [-1 0 1]
    #
    # @api public
    def <=>(other)
      other.is_a?(type) &&
        [name, from, event_name] <=> [other.name, other.from, other.event_name]
    end
    alias eql? ==
  end # HookEvent
end # FiniteMachine
