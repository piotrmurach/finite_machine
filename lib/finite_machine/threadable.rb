# encoding: utf-8

module FiniteMachine
  module Threadable
    module InstanceMethods
      @@sync = Sync.new

      def sync_exclusive(&block)
        @@sync.synchronize(:EX, &block)
      end

      def sync_shared(&block)
        @@sync.synchronize(:SH, &block)
      end
    end

    def self.included(base)
      base.extend ClassMethods
      base.module_eval do
        include InstanceMethods
      end
    end

    module ClassMethods
      include InstanceMethods

      def attr_threadsafe(*attrs)
        attrs.flatten.each do |attr|
          class_eval <<-RUBY_EVAL, __FILE__, __LINE__ + 1
            def #{attr}(*args)
              if args.empty?
                sync_shared { @#{attr} }
              else
                self.#{attr} = args.shift
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
