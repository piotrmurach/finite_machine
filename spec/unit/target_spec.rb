# encoding: utf-8

require 'spec_helper'

describe FiniteMachine, '#target' do

  it "allows to target external object" do
    Car = Class.new do
      attr_accessor :reverse_lights

      def turn_reverse_lights_off
        self.reverse_lights = false
      end

      def turn_reverse_lights_on
        self.reverse_lights = true
      end

      def engine
        context = self
        @engine ||= FiniteMachine.define do
          initial :neutral

          target context

          events {
            event :forward, [:reverse, :neutral] => :one
            event :shift, :one => :two
            event :shift, :two => :one
            event :back,  [:neutral, :one] => :reverse
          }

          callbacks {
            on_enter :reverse do |event|
              context.turn_reverse_lights_on
            end

            on_exit :reverse do |event|
              context.turn_reverse_lights_off
            end
          }
        end
      end
    end
    car = Car.new
    expect(car.engine.current).to eql(:neutral)
    car.engine.back
    expect(car.engine.current).to eql(:reverse)
    expect(car.reverse_lights).to be_true
    car.engine.forward
    expect(car.engine.current).to eql(:one)
    expect(car.reverse_lights).to be_false
  end
end
