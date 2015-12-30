# encoding: utf-8

module FiniteMachine
  # A class reponsible for registering callbacks
  class Hooks
    include Threadable

    attr_threadsafe :collection

    # Initialize a collection of hoooks
    #
    # @example
    #   Hoosk.new(machine)
    #
    # @api public
    def initialize
      @collection = Hash.new do |events_hash, event_type|
        events_hash[event_type] = Hash.new do |state_hash, name|
          state_hash[name] = []
        end
      end
    end

    # Register callback
    #
    # @param [String] event_type
    # @param [String] name
    # @param [Proc]   callback
    #
    # @example
    #   hooks.register HookEvent::Enter, :green do ... end
    #
    # @example
    #   hooks.register HookEvent::Before, :any do ... end
    #
    # @return [Hash]
    #
    # @api public
    def register(event_type, name, callback)
      collection[event_type][name] << callback
    end

    # Unregister callback
    #
    # @param [String] event_type
    # @param [String] name
    # @param [Proc]   callback
    #
    # @example
    #   hooks.unregister HookEvent::Enter, :green do ... end
    #
    # @return [Hash]
    #
    # @api public
    def unregister(event_type, name, callback)
      callbacks = collection[event_type][name]
      callbacks.delete(callback)
    end

    # Return all hooks matching event and state
    #
    # @param [String] event_type
    # @param [String] event_state
    # @param [Event] event
    #
    # @example
    #   hooks.call(HookEvent::Enter, :green, Event.new)
    #
    # @return [Hash]
    #
    # @api public
    def call(event_type, event_state, &block)
      collection[event_type][event_state].each(&block)
    end

    # Check if collection has any elements
    #
    # @return [Boolean]
    #
    # @api public
    def empty?
      collection.empty?
    end

    # Remove all callbacks
    #
    # @api public
    def clear
      collection.clear
    end

    # String representation
    #
    # @return [String]
    #
    # @api public
    def to_s
      self.inspect
    end

    # String representation
    #
    # @return [String]
    #
    # @api public
    def inspect
      "<##{self.class}:0x#{object_id.to_s(16)} @collection=#{collection.inspect}>"
    end
  end # Hooks
end # FiniteMachine
