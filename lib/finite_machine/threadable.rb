# frozen_string_literal: true

require_relative "two_phase_lock"

module FiniteMachine
  # A mixin to allow instance methods to be synchronized
  module Threadable
    module InstanceMethods
      # Exclusive lock
      #
      # @return [nil]
      #
      # @api public
      def sync_exclusive(&block)
        TwoPhaseLock.synchronize(:EX, &block)
      end

      # Shared lock
      #
      # @return [nil]
      #
      # @api public
      def sync_shared(&block)
        TwoPhaseLock.synchronize(:SH, &block)
      end
    end

    # Module hook
    #
    # @return [nil]
    #
    # @api private
    def self.included(base)
      base.extend ClassMethods
      base.module_eval do
        include InstanceMethods
      end
    end

    private_class_method :included

    module ClassMethods
      include InstanceMethods

      # Defines threadsafe attributes for a class
      #
      # @example
      #   attr_threadable :errors, :events
      #
      # @example
      #   attr_threadable :errors, default: []
      #
      # @return [nil]
      #
      # @api public
      def attr_threadsafe(*attrs)
        opts    = attrs.last.is_a?(::Hash) ? attrs.pop : {}
        default = opts.fetch(:default, nil)
        attrs.flatten.each do |attr|
          class_eval <<-RUBY_EVAL, __FILE__, __LINE__ + 1
            def #{attr}(*args)
              value = args.shift
              if value
                self.#{attr} = value
              elsif instance_variables.include?(:@#{attr})
                sync_shared { @#{attr} }
              elsif #{!default.nil?}
                sync_shared { instance_variable_set(:@#{attr}, #{default}) }
              end
            end
            alias_method '#{attr}?', '#{attr}'

            def #{attr}=(value)
              sync_exclusive { @#{attr} = value }
            end
          RUBY_EVAL
        end
      end
    end
  end # Threadable
end # FiniteMachine
