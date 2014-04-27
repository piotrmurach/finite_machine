# encoding: utf-8

module FiniteMachine
  # A generic listener interface
  class Listener
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
    alias_method :handle_delivery, :call
  end # Listener
end # FiniteMachine
