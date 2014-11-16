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

    class Bug
      def pending?
        false
      end
    end
  }

  it "passes context to conditionals" do
    called = []
    fsm = FiniteMachine.define do
      initial :red

      events {
        event :go, :red => :green,
              if: -> (context) { called << "cond_red_green(#{context})"; true}
        event :stop, from: :any do
          choice :red,
                 if: -> (context) { called << "cond_any_red(#{context})"; true }
        end
      }
    end

    expect(fsm.current).to eq(:red)

    fsm.go
    expect(fsm.current).to eq(:green)
    expect(called).to eq(["cond_red_green(#{fsm})"])

    fsm.stop
    expect(fsm.current).to eq(:red)
    expect(called).to match_array([
      "cond_red_green(#{fsm})",
      "cond_any_red(#{fsm})"
    ])
  end

  it "passes context & arguments to conditionals" do
    called = []
    fsm = FiniteMachine.define do
      initial :red

      events {
        event :go,  :red => :green,
              if: proc { |_, a| called << "cond_red_green(#{a})"; true }
        event :stop, from: :any do
          choice :red,
                 if: proc { |_, b| called << "cond_any_red(#{b})"; true }
        end
      }
    end

    expect(fsm.current).to eq(:red)

    fsm.go(:foo)
    expect(fsm.current).to eq(:green)
    expect(called).to eq(["cond_red_green(foo)"])

    fsm.stop(:bar)
    expect(fsm.current).to eq(:red)
    expect(called).to match_array([
      "cond_red_green(foo)",
      "cond_any_red(bar)"
    ])
  end

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
      expect(car.engine_on?).to be false
      expect(fsm.current).to eql(:neutral)
      fsm.start
      expect(fsm.current).to eql(:neutral)

      car.turn_engine_on
      expect(car.engine_on?).to be true
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
      expect(car.engine_on?).to be false
      expect(fsm.current).to eql(:neutral)
      fsm.start
      expect(fsm.current).to eql(:neutral)

      car.turn_engine_on
      expect(car.engine_on?).to be true
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
      expect(car.engine_on?).to be false
      expect(fsm.current).to eql(:neutral)
      fsm.start
      expect(fsm.current).to eql(:neutral)

      car.turn_engine_on
      expect(car.engine_on?).to be true
      expect(fsm.current).to eql(:neutral)
      fsm.start
      expect(fsm.current).to eql(:one)
    end
  end

  context 'when same event name' do
    it "preservers conditions for the same named event" do
      bug = Bug.new
      fsm = FiniteMachine.define do
        initial :initial

        target bug

        events {
          event :bump, :initial => :low
          event :bump, :low     => :medium, if: :pending?
          event :bump, :medium  => :high
        }
      end
      expect(fsm.current).to eq(:initial)
      fsm.bump
      expect(fsm.current).to eq(:low)
      fsm.bump
      expect(fsm.current).to eq(:low)
    end

    it "allows for static choice based on branching condition" do
      fsm = FiniteMachine.define do
        initial :company_form

        events {
          event :next, :company_form => :agreement_form, if: -> { false }
          event :next, :company_form => :promo_form,     if: -> { false }
          event :next, :company_form => :official_form,  if: -> { true }
        }
      end
      expect(fsm.current).to eq(:company_form)
      fsm.next
      expect(fsm.current).to eq(:official_form)
    end

    it "allows for dynamic choice based on branching condition" do
      fsm = FiniteMachine.define do
        initial :company_form

        events {
          event :next, :company_form => :agreement_form, if: proc { |_, a| a < 1 }
          event :next, :company_form => :promo_form,     if: proc { |_, a| a == 1 }
          event :next, :company_form => :official_form,  if: proc { |_, a| a > 1 }
        }
      end
      expect(fsm.current).to eq(:company_form)

      fsm.next(0)
      expect(fsm.current).to eq(:agreement_form)
      fsm.restore!(:company_form)
      expect(fsm.current).to eq(:company_form)

      fsm.next(1)
      expect(fsm.current).to eq(:promo_form)
      fsm.restore!(:company_form)
      expect(fsm.current).to eq(:company_form)

      fsm.next(2)
      expect(fsm.current).to eq(:official_form)
    end
  end
end
