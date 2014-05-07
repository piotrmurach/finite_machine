# encoding: utf-8

require 'spec_helper'

describe FiniteMachine, ':if, :unless' do
  before(:each) {
    Car = Class.new do
      attr_accessor :engine_on

      def turn_engine_on
        @engine_on = true
      end

      def turn_engine_off
        @engine_on = false
      end

      def engine_on?
        !!@engine_on
      end
    end
  }

  it "allows to cancel event with :if option" do
    called = []

    fsm = FiniteMachine.define do
      initial :green

      events {
        event :slow, :green => :yellow, if: -> { return false }
        event :stop, :yellow => :red
      }

      callbacks {
        # generic callbacks
        on_enter      do |event| called << 'on_enter' end
        on_transition do |event| called << 'on_transition' end
        on_exit       do |event| called << 'on_exit' end

        # state callbacks
        on_enter :green do |event| called << 'on_enter_green' end
        on_enter :yellow do |event| called << "on_enter_yellow" end

        on_transition :green  do |event| called << 'on_transition_green' end
        on_transition :yellow do |event| called << "on_transition_yellow" end

        on_exit :green  do |event| called << 'on_exit_green' end
        on_exit :yellow do |event| called << "on_exit_yellow" end
      }
    end

    expect(fsm.current).to eql(:green)
    called = []
    fsm.slow
    expect(fsm.current).to eql(:green)
    expect(called).to eql([])
  end

  it "allows to cancel event with :unless option" do
    called = []

    fsm = FiniteMachine.define do
      initial :green

      events {
        event :slow, :green => :yellow, unless: -> { true }
        event :stop, :yellow => :red
      }

      callbacks {
        # generic callbacks
        on_enter      do |event| called << 'on_enter' end
        on_transition do |event| called << 'on_transition' end
        on_exit       do |event| called << 'on_exit' end

        # state callbacks
        on_enter :green do |event| called << 'on_enter_green' end
        on_enter :yellow do |event| called << "on_enter_yellow" end

        on_transition :green  do |event| called << 'on_transition_green' end
        on_transition :yellow do |event| called << "on_transition_yellow" end

        on_exit :green  do |event| called << 'on_exit_green' end
        on_exit :yellow do |event| called << "on_exit_yellow" end
      }
    end

    expect(fsm.current).to eql(:green)
    called = []
    fsm.slow
    expect(fsm.current).to eql(:green)
    expect(called).to eql([])
  end

  it "allows to combine conditionals" do
    conditions = []

    fsm = FiniteMachine.define do
      initial :green

      events {
        event :slow, :green => :yellow,
          if: [ -> { conditions << 'first_if'; return true },
                -> { conditions << 'second_if'; return true}],
          unless: -> { conditions << 'first_unless'; return true }
        event :stop, :yellow => :red
      }
    end

    expect(fsm.current).to eql(:green)
    fsm.slow
    expect(fsm.current).to eql(:green)
    expect(conditions).to eql([
      'first_if',
      'second_if',
      'first_unless'
    ])
  end

  context "conditional branches" do
    it "allow to follow positive state branch" do
      car = Car.new

      fsm = FiniteMachine.define do
        initial :green

        target car

        events {
          event :follow, :green => :positive, if: ->(_target, param) { param } 
          event :follow, :green => :negative, unless: ->(_target, param) { param }
        }
      end
      
      fsm.follow(true)
      expect(fsm.current).to eql(:positive)
    end

    it "allow to follow negative state branch" do
      car = Car.new

      fsm = FiniteMachine.define do
        initial :green

        target car 

        events {
          event :follow, :green => :positive, if: ->(_target, param)  { param } 
          event :follow, :green => :negative, unless: ->(_target, param) { param }
        }
      end

      fsm.follow(false)
      expect(fsm.current).to eql(:negative)
    end
  end

  context 'when proc' do
    it "specifies :if and :unless" do
      car = Car.new

      fsm = FiniteMachine.define do
        initial :neutral

        target car

        events {
          event :start, :neutral => :one, if: proc {|_car| _car.engine_on? }
          event :shift, :one => :two
        }
      end
      car.turn_engine_off
      expect(car.engine_on?).to be_false
      expect(fsm.current).to eql(:neutral)
      fsm.start
      expect(fsm.current).to eql(:neutral)

      car.turn_engine_on
      expect(car.engine_on?).to be_true
      expect(fsm.current).to eql(:neutral)
      fsm.start
      expect(fsm.current).to eql(:one)
    end

    it "passes arguments to the scope" do
      car = Car.new

      fsm = FiniteMachine.define do
        initial :neutral

        target car

        events {
          event :start, :neutral => :one, if: proc { |_car, state|
            _car.engine_on = state
            _car.engine_on?
          }
          event :shift, :one => :two
        }
      end
      fsm.start(false)
      expect(fsm.current).to eql(:neutral)
      fsm.start(true)
      expect(fsm.current).to eql(:one)
    end
  end

  context 'when symbol' do
    it "specifies :if and :unless" do
      car = Car.new

      fsm = FiniteMachine.define do
        initial :neutral

        target car

        events {
          event :start, :neutral => :one, if: :engine_on?
          event :shift, :one => :two
        }
      end
      car.turn_engine_off
      expect(car.engine_on?).to be_false
      expect(fsm.current).to eql(:neutral)
      fsm.start
      expect(fsm.current).to eql(:neutral)

      car.turn_engine_on
      expect(car.engine_on?).to be_true
      expect(fsm.current).to eql(:neutral)
      fsm.start
      expect(fsm.current).to eql(:one)
    end
  end

  context 'when string' do
    it "specifies :if and :unless" do
      car = Car.new

      fsm = FiniteMachine.define do
        initial :neutral

        target car

        events {
          event :start, :neutral => :one, if: "engine_on?"
          event :shift, :one => :two
        }
      end
      car.turn_engine_off
      expect(car.engine_on?).to be_false
      expect(fsm.current).to eql(:neutral)
      fsm.start
      expect(fsm.current).to eql(:neutral)

      car.turn_engine_on
      expect(car.engine_on?).to be_true
      expect(fsm.current).to eql(:neutral)
      fsm.start
      expect(fsm.current).to eql(:one)
    end
  end
end
