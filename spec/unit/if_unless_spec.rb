# encoding: utf-8

require 'spec_helper'

describe FiniteMachine, ':if, :unless' do
  before(:all) {
    Car = Class.new do
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

  it "specifies :if and :unless with proc" do
    car = Car.new

    fsm = FiniteMachine.define do
      initial :neutral

      target car

      events {
        event :start, :neutral => :one, if: proc {|car| car.engine_on? }
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

  it "specifies :if and :unless with symbol" do
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

  it "specifies :if and :unless with string" do
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
