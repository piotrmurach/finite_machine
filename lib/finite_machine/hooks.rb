# frozen_string_literal: true

require 'concurrent/map'

require_relative 'hook_event'

module FiniteMachine
  # A class reponsible for registering callbacks
  class Hooks
    attr_reader :hooks_map

    # Initialize a hooks_map of hooks
    #
    # @example
    #   Hoosk.new(machine)
    #
    # @api public
    def initialize
      @hooks_map = Concurrent::Map.new do |events_hash, event_type|
        events_hash[event_type] = Concurrent::Map.new do |state_hash, name|
          state_hash[name] = []
        end
      end
    end

    # Finds all hooks for the event type
    #
    # @param [Symbol] name
    #
    # @example
    #   hooks[HookEvent::Enter][:go] # => [-> { }]
    #
    # @return [Array[Transition]]
    #   the transitions matching event name
    #
    # @api public
    def find(name)
      @hooks_map.fetch(name) { [] }
    end
    alias [] find

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
    #   hooks.register HookEvent::Before, any_state do ... end
    #
    # @return [Hash]
    #
    # @api public
    def register(event_type, name, callback)
      @hooks_map[event_type][name] << callback
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
      callbacks = @hooks_map[event_type][name]
      callbacks.delete(callback)
    end

    # Return all hooks matching event and state
    #
    # @param [String] event_type
    # @param [String] event_state
    #
    # @example
    #   hooks.call(HookEvent::Enter, :green)
    #
    # @return [Hash]
    #
    # @api public
    def call(event_type, event_state, &block)
      @hooks_map[event_type][event_state].each(&block)
    end

    # Check if hooks_map has any elements
    #
    # @return [Boolean]
    #
    # @api public
    def empty?
      @hooks_map.empty?
    end

    # Remove all callbacks
    #
    # @api public
    def clear
      @hooks_map.clear
    end

    # String representation
    #
    # @return [String]
    #
    # @api public
    def to_s
      hash = {}
      @hooks_map.each_pair do |event_type, nested_hash|
        hash[event_type] = {}
        nested_hash.each_pair do |name, callbacks|
          hash[event_type][name] = callbacks
        end
      end
      hash.to_s
    end

    # String representation
    #
    # @return [String]
    #
    # @api public
    def inspect
      "<##{self.class}:0x#{object_id.to_s(16)} @hooks_map=#{self}>"
    end
  end # Hooks
end # FiniteMachine
