# frozen_string_literal: true

RSpec.describe FiniteMachine, '#target' do
  it "allows to target external object" do
    stub_const("Car", Class.new do
      attr_accessor :reverse_lights

      def turn_reverse_lights_off
        @reverse_lights = false
      end

      def turn_reverse_lights_on
        @reverse_lights = true
      end

      def reverse_lights?
        @reverse_lights ||= false
      end

      def engine
        context = self
        @engine ||= FiniteMachine.define(target: context) do
          initial :neutral

          events {
            event :forward, [:reverse, :neutral] => :one
            event :shift, :one => :two
            event :shift, :two => :one
            event :back,  [:neutral, :one] => :reverse
          }

          callbacks {
            on_enter :reverse do |event|
              target.turn_reverse_lights_on
            end

            on_exit :reverse do |event|
              target.turn_reverse_lights_off
            end
          }
        end
      end
    end)
    car = Car.new
    expect(car.reverse_lights?).to be(false)
    expect(car.engine.current).to eql(:neutral)
    car.engine.back
    expect(car.engine.current).to eql(:reverse)
    expect(car.reverse_lights?).to be(true)
    car.engine.forward
    expect(car.engine.current).to eql(:one)
    expect(car.reverse_lights?).to be(false)
  end

  it "propagates method call" do
    fsm = FiniteMachine.define do
      initial :green
      events {
        event :slow, :green => :yellow
      }

      callbacks {
        on_enter_yellow do |event|
          uknown_method
        end
      }
    end
    expect(fsm.current).to eql(:green)
    expect { fsm.slow }.to raise_error(StandardError)
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
    stub_const("Car", Class.new do
      attr_accessor :reverse_lights
      attr_accessor :called

      def turn_reverse_lights_off
        @reverse_lights = false
      end

      def turn_reverse_lights_on
        @reverse_lights = true
      end

      def reverse_lights?
        @reverse_lights ||= false
      end

      def engine
        self.called ||= []

        @engine ||= FiniteMachine.define(target: self) do
          initial :neutral

          events {
            event :forward, [:reverse, :neutral] => :one
            event :shift, :one => :two
            event :shift, :two => :one
            event :back,  [:neutral, :one] => :reverse
          }

          callbacks {
            on_enter :reverse do |event|
              target.called << 'on_enter_reverse'
              target.turn_reverse_lights_on
              forward('Piotr!')
            end
            on_before :forward do |event, name|
              target.called << "on_enter_forward with #{name}"
            end
          }
        end
      end
    end)

    car = Car.new
    expect(car.reverse_lights?).to be(false)
    expect(car.engine.current).to eql(:neutral)
    car.engine.back
    expect(car.engine.current).to eql(:one)
    expect(car.called).to eql([
      'on_enter_reverse',
      'on_enter_forward with Piotr!'
    ])
  end

  it "allows to access target inside the callback" do
    context = double(:context)
    called = nil
    fsm = FiniteMachine.define(target: context) do
      initial :green

      events {
        event :slow, :green  => :yellow
        event :stop, :yellow => :red
      }
      callbacks {
        on_enter_yellow do |event|
          called = target
        end
      }
    end
    expect(fsm.current).to eql(:green)
    fsm.slow
    expect(called).to eq(context)
  end

  it "allows to differentiate between same named methods" do
    called = []
    stub_const("Car", Class.new do
      def initialize(called)
        @called = called
      end
      def save
        @called << 'car save called'
      end
    end)

    car = Car.new(called)
    fsm = FiniteMachine.define(target: car) do
      initial :unsaved

      events {
        event :validate, :unsaved => :valid
        event :save, :valid => :saved
      }

      callbacks {
        on_enter :valid do |event|
          target.save
          save
        end
        on_after :save do |event|
          called << 'event save called'
        end
      }
    end
    expect(fsm.current).to eql(:unsaved)
    fsm.validate
    expect(fsm.current).to eql(:saved)
    expect(called).to eq([
      'car save called',
      'event save called'
    ])
  end
end
