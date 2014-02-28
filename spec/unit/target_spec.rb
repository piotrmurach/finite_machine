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
              turn_reverse_lights_on
            end

            on_exit :reverse do |event|
              turn_reverse_lights_off
            end
          }
        end
      end
    end
    car = Car.new
    expect(car.reverse_lights).to be_false
    expect(car.engine.current).to eql(:neutral)
    car.engine.back
    expect(car.engine.current).to eql(:reverse)
    expect(car.reverse_lights).to be_true
    car.engine.forward
    expect(car.engine.current).to eql(:one)
    expect(car.reverse_lights).to be_false
  end

  it "references machine methods inside callback" do
    called = []
    fsm = FiniteMachine.define do
      initial :green

      events {
        event :slow,  :green  => :yellow
        event :stop,  :yellow => :red
        event :ready, :red    => :yellow
        event :go,    :yellow => :green
      }

      callbacks {
        on_enter_yellow do |event|
          stop(:now)
        end

        on_enter_red do |event, param|
          called << "#{event.from} #{param}"
        end
      }
    end

    expect(fsm.current).to eql(:green)
    fsm.slow
    expect(fsm.current).to eql(:red)
    expect(called).to eql(['yellow now'])
  end

  it "allows context methods take precedence over machine ones" do
    Car = Class.new do
      attr_accessor :reverse_lights
      attr_accessor :called

      def turn_reverse_lights_off
        self.reverse_lights = false
      end

      def turn_reverse_lights_on
        self.reverse_lights = true
      end

      def engine
        self.called ||= []
        context ||= self
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
              called << 'on_enter_reverse'
              turn_reverse_lights_on
              forward('Piotr!')
            end
            on_enter :forward do |event, name|
              called << "on_enter_forward with #{name}"
            end
          }
        end
      end
    end

    car = Car.new
    expect(car.reverse_lights).to be_false
    expect(car.engine.current).to eql(:neutral)
    car.engine.back
    expect(car.engine.current).to eql(:one)
    expect(car.called).to eql([
      'on_enter_reverse',
      'on_enter_forward with Piotr!'
    ])
  end
end
