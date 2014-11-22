# encoding: utf-8

require 'spec_helper'

RSpec.describe FiniteMachine::Definition, '#alias_target' do

  before do
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
  end

  it "aliases target" do
    car = Car.new
    fsm = FiniteMachine.new
    fsm.target(car)

    expect(fsm.target).to eq(car)
    expect { fsm.car }.to raise_error(NoMethodError)

    fsm.alias_target(:delorean)
    expect(fsm.delorean).to eq(car)
  end

  it "scopes the target alias to a state machine instance" do
    delorean = Car.new
    batmobile = Car.new
    fsm_a = FiniteMachine.new
    fsm_a.target(delorean)
    fsm_b = FiniteMachine.new
    fsm_b.target(batmobile)

    fsm_a.alias_target(:delorean)
    fsm_b.alias_target(:batmobile)

    expect(fsm_a.delorean).to eq(delorean)
    expect { fsm_a.batmobile }.to raise_error(NoMethodError)

    expect(fsm_b.batmobile).to eq(batmobile)
    expect { fsm_b.delorean }.to raise_error(NoMethodError)
  end

  context 'when inside definition' do
    before do
      class Engine < FiniteMachine::Definition
        initial :neutral

        alias_target :car

        events {
          event :forward, [:reverse, :neutral] => :one
          event :shift, :one => :two
          event :shift, :two => :one
          event :back,  [:neutral, :one] => :reverse
        }

        callbacks {
          on_enter :reverse do |event|
            car.turn_reverse_lights_on
          end

          on_exit :reverse do |event|
            car.turn_reverse_lights_off
          end
        }

        handlers {
          handle FiniteMachine::InvalidStateError do |exception| end
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
      car = Car.new
      engine = Engine.new
      engine.target car
      expect(engine.current).to eq(:neutral)

      engine.forward
      expect(engine.current).to eq(:one)
      expect(car.reverse_lights?).to be false

      engine.back
      expect(engine.current).to eq(:reverse)
      expect(car.reverse_lights?).to be true
    end
  end
end
