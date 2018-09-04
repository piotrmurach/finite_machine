# frozen_string_literal: true

module FiniteMachine
  # A generic listener interface
  class Listener
    # Initialize a listener
    #
    # @api private
    def initialize(*args)
      @name = args.unshift
    end

    # Define event delivery handler
    #
    # @api public
    def on_delivery(&block)
      @on_delivery = block
      self
    end

    # Invoke event handler
    #
    # @api private
    def call(*args)
      @on_delivery.call(*args) if @on_delivery
    end
    alias handle_delivery call
  end # Listener
end # FiniteMachine
