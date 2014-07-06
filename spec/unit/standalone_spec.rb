# encoding: utf-8

require 'spec_helper'

describe FiniteMachine::Definition, 'definition' do

  before do
    class Engine < FiniteMachine::Definition
      initial :neutral

      events {
        event :forward, [:reverse, :neutral] => :one
        event :shift, :one => :two
        event :shift, :two => :one
        event :back,  [:neutral, :one] => :reverse
      }

      callbacks {
        on_enter :reverse do |event|
          turn_reverse_lights_on
        end

        on_exit :reverse do |event|
          turn_reverse_lights_off
        end
      }

      handlers {
        handle FiniteMachine::InvalidStateError do |exception|  end
      }
    end
  end

  it "creates unique instances" do
    engine_a = Engine.new
    engine_b = Engine.new
    expect(engine_a).not_to be(engine_b)

    engine_a.forward
    expect(engine_a.current).to eq(:one)
    expect(engine_b.current).to eq(:neutral)
  end

  it "allows to create standalone machine" do
    Car = Class.new do
      def turn_reverse_lights_off
        @reverse_lights = false
      end

      def turn_reverse_lights_on
        @reverse_lights = true
      end

      def reverse_lights?
        @reverse_lights ||= false
      end
    end

    car = Car.new
    engine = Engine.new
    engine.target car
    expect(engine.current).to eq(:neutral)

    engine.forward
    expect(engine.current).to eq(:one)
    expect(car.reverse_lights?).to be_false

    engine.back
    expect(engine.current).to eq(:reverse)
    expect(car.reverse_lights?).to be_true
  end
end
