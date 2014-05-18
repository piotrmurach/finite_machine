# encoding: utf-8

module FiniteMachine
  # A class responsible for event notification
  class Event
    include Threadable

    MESSAGE = :trigger

    # Event state
    attr_threadsafe :state

    # Event type
    attr_threadsafe :type

    # Data associated with the event
    attr_threadsafe :data

    # Transition associated with the event
    attr_threadsafe :transition

    def initialize(state, transition, *data, &block)
      @state = state
      @transition = transition
      @data  = *data
      @type  = self.class.event_name
    end

    def notify(subscriber, *args, &block)
      if subscriber.respond_to? MESSAGE
        subscriber.public_send(MESSAGE, self, *args, &block)
      end
    end

    class Anystate < Event; end

    class Enterstate < Anystate; end

    class Transitionstate < Anystate; end

    class Exitstate < Anystate; end

    class Anyaction < Event; end

    class Enteraction < Anyaction; end

    class Transitionaction < Anyaction; end

    class Exitaction < Anyaction; end

    EVENTS = Anystate, Enterstate, Transitionstate, Exitstate,
             Anyaction, Enteraction, Transitionaction, Exitaction

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
  end # Event
end # FiniteMachine
