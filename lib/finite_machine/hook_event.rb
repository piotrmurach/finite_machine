# encoding: utf-8

module FiniteMachine
  # A class responsible for event notification
  class HookEvent
    include Threadable

    MESSAGE = :trigger

    # HookEvent state
    attr_threadsafe :state

    # HookEvent type
    attr_threadsafe :type

    # Data associated with the event
    attr_threadsafe :data

    # Transition associated with the event
    attr_threadsafe :transition

    def initialize(state, transition, *data, &block)
      @state = state
      @transition = transition
      @data       = *data
      @type       = self.class
      freeze
    end

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

    def self.event_name
      name.split('::').last.downcase.to_sym
    end

    def self.to_s
      event_name
    end

    EVENTS.each do |event|
      (class << self; self; end).class_eval do
        define_method(event.event_name) { event }
      end
    end
  end # HookEvent
end # FiniteMachine
