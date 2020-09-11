# frozen_string_literal: true

require "concurrent/map"

require_relative "hook_event"

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
      @hooks_map = Concurrent::Map.new do |events_hash, hook_event|
        events_hash[hook_event] = Concurrent::Map.new do |state_hash, name|
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
      @hooks_map[name]
    end
    alias [] find

    # Register callback
    #
    # @param [String] hook_event
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
    def register(hook_event, name, callback)
      @hooks_map[hook_event][name] << callback
    end

    # Unregister callback
    #
    # @param [String] hook_event
    # @param [String] name
    # @param [Proc]   callback
    #
    # @example
    #   hooks.unregister HookEvent::Enter, :green do ... end
    #
    # @return [Hash]
    #
    # @api public
    def unregister(hook_event, name, callback)
      @hooks_map[hook_event][name].delete(callback)
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
      @hooks_map.each_pair do |hook_event, nested_hash|
        hash[hook_event] = {}
        nested_hash.each_pair do |name, callbacks|
          hash[hook_event][name] = callbacks
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
