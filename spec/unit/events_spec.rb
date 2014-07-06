# encoding: utf-8

require 'spec_helper'

describe FiniteMachine, 'events' do

  it "allows for hash rocket syntax to describe transition" do
    fsm = FiniteMachine.define do
      initial :green

      events {
        event :slow, :green  => :yellow
        event :stop, :yellow => :red
      }
    end

    expect(fsm.current).to eql(:green)
    fsm.slow
    expect(fsm.current).to eql(:yellow)
    fsm.stop
    expect(fsm.current).to eql(:red)
  end

  it "allows to add event without events scope" do
    fsm = FiniteMachine.define do
      initial :green

      event :slow, :green  => :yellow
      event :stop, :yellow => :red
    end

    expect(fsm.current).to eql(:green)
  end

  it "allows for (:from | :to) key pairs to describe transition" do
    fsm = FiniteMachine.define do
      initial :green

      events {
        event :slow, from: :green, to: :yellow
        event :stop, from: :yellow, to: :red
      }
    end

    expect(fsm.current).to eql(:green)
    fsm.slow
    expect(fsm.current).to eql(:yellow)
    fsm.stop
    expect(fsm.current).to eql(:red)
  end

  it "permits no-op event without 'to' transition" do
    fsm = FiniteMachine.define do
      initial :green

      events {
        event :noop,  from: :green
        event :slow,  from: :green,  to: :yellow
        event :stop,  from: :yellow, to: :red
        event :ready, from: :red,    to: :yellow
        event :go,    from: :yellow, to: :green
      }
    end

    expect(fsm.current).to eql(:green)

    expect(fsm.can?(:noop)).to be true
    expect(fsm.can?(:slow)).to be true

    fsm.noop
    expect(fsm.current).to eql(:green)
    fsm.slow
    expect(fsm.current).to eql(:yellow)

    expect(fsm.cannot?(:noop)).to be true
    expect(fsm.cannot?(:slow)).to be true
  end

  it "permits event from any state with :any 'from'" do
    fsm = FiniteMachine.define do
      initial :green

      events {
        event :slow,  from: :green,  to: :yellow
        event :stop,  from: :yellow, to: :red
        event :ready, from: :red,    to: :yellow
        event :go,    from: :yellow, to: :green
        event :run,   from: :any,    to: :green
      }
    end

    expect(fsm.current).to eql(:green)

    fsm.slow
    expect(fsm.current).to eql(:yellow)
    fsm.run
    expect(fsm.current).to eql(:green)

    fsm.slow
    expect(fsm.current).to eql(:yellow)
    fsm.stop
    expect(fsm.current).to eql(:red)
    fsm.run
    expect(fsm.current).to eql(:green)

    fsm.slow
    expect(fsm.current).to eql(:yellow)
    fsm.go
    expect(fsm.current).to eql(:green)
    fsm.run
    expect(fsm.current).to eql(:green)
  end

  it "permits event from any state without 'from'" do
    fsm = FiniteMachine.define do
      initial :green

      events {
        event :slow,  from: :green,  to: :yellow
        event :stop,  from: :yellow, to: :red
        event :ready, from: :red,    to: :yellow
        event :go,    from: :yellow, to: :green
        event :run,                  to: :green
      }
    end

    expect(fsm.current).to eql(:green)

    fsm.slow
    expect(fsm.current).to eql(:yellow)
    fsm.run
    expect(fsm.current).to eql(:green)

    fsm.slow
    expect(fsm.current).to eql(:yellow)
    fsm.stop
    expect(fsm.current).to eql(:red)
    fsm.run
    expect(fsm.current).to eql(:green)

    fsm.slow
    expect(fsm.current).to eql(:yellow)
    fsm.go
    expect(fsm.current).to eql(:green)
    fsm.run
    expect(fsm.current).to eql(:green)
  end

  it "raises error on invalid transition" do
    fsm = FiniteMachine.define do
      initial :green

      events {
        event :slow,  from: :green,  to: :yellow
        event :stop,  from: :yellow, to: :red
      }
    end

    expect(fsm.current).to eql(:green)

    expect { fsm.stop }.to raise_error(FiniteMachine::InvalidStateError, /state 'green'/)
  end

  it "allows to transition to any state" do
    fsm = FiniteMachine.define do
      initial :green

      events {
        event :slow,  from: :green,  to: :yellow
        event :stop,  from: :yellow, to: :red
      }
    end
    expect(fsm.current).to eql(:green)
    expect(fsm.can?(:stop)).to be false
    fsm.stop!
    expect(fsm.current).to eql(:red)
  end

  context 'when multiple from states' do
    it "allows for array from key" do
      fsm = FiniteMachine.define do
        initial :green

        events {
          event :slow,  :green            => :yellow
          event :stop,  [:green, :yellow] => :red
          event :ready, :red              => :yellow
          event :go,    [:yellow, :red]   => :green
        }
      end

      expect(fsm.current).to eql(:green)

      expect(fsm.can?(:slow)).to be true
      expect(fsm.can?(:stop)).to be true
      expect(fsm.cannot?(:ready)).to be true
      expect(fsm.cannot?(:go)).to be true

      fsm.slow;  expect(fsm.current).to eql(:yellow)
      fsm.stop;  expect(fsm.current).to eql(:red)
      fsm.ready; expect(fsm.current).to eql(:yellow)
      fsm.go;    expect(fsm.current).to eql(:green)

      fsm.stop; expect(fsm.current).to eql(:red)
      fsm.go;   expect(fsm.current).to eql(:green)
    end

    it "allows for hash of states" do
      fsm = FiniteMachine.define do
        initial :green

        events {
          event :slow,  :green  => :yellow
          event :stop,  :green  => :red,   :yellow => :red
          event :ready, :red    => :yellow
          event :go,    :yellow => :green, :red    => :green
        }
      end

      expect(fsm.current).to eql(:green)

      expect(fsm.can?(:slow)).to be true
      expect(fsm.can?(:stop)).to be true
      expect(fsm.cannot?(:ready)).to be true
      expect(fsm.cannot?(:go)).to be true

      fsm.slow;  expect(fsm.current).to eql(:yellow)
      fsm.stop;  expect(fsm.current).to eql(:red)
      fsm.ready; expect(fsm.current).to eql(:yellow)
      fsm.go;    expect(fsm.current).to eql(:green)

      fsm.stop; expect(fsm.current).to eql(:red)
      fsm.go;   expect(fsm.current).to eql(:green)
    end
  end

  it "groups events with the same name" do
    fsm = FiniteMachine.define do
      initial :green

      events {
        event :stop,  :green  => :yellow
        event :stop,  :yellow => :red
        event :stop,  :red    => :pink
        event :cycle, [:yellow, :red, :pink] => :green
      }
    end

    expect(fsm.current).to eql(:green)
    expect(fsm.can?(:stop)).to be true
    fsm.stop
    expect(fsm.current).to eql(:yellow)
    fsm.stop
    expect(fsm.current).to eql(:red)
    fsm.stop
    expect(fsm.current).to eql(:pink)
    fsm.cycle
    expect(fsm.current).to eql(:green)
    fsm.stop
    expect(fsm.current).to eql(:yellow)
  end

  it "groups transitions under one event name" do
    fsm = FiniteMachine.define do
      initial :initial

      events {
        event :bump, :initial => :low,
                     :low     => :medium,
                     :medium  => :high
      }
    end

    expect(fsm.current).to eq(:initial)
    fsm.bump; expect(fsm.current).to eq(:low)
    fsm.bump; expect(fsm.current).to eq(:medium)
    fsm.bump; expect(fsm.current).to eq(:high)
  end

  it "returns values for events" do
    fsm = FiniteMachine.define do
      initial :neutral

      events {
        event :start,  :neutral   => :engine_on
        event :drive,  :engine_on => :running, if: -> { return false }
        event :stop,   :any       => :neutral
      }

      callbacks {
        on_before(:drive) { }
        on_after(:stop)   { }
      }
    end

    expect(fsm.current).to eql(:neutral)
    expect(fsm.start).to eql(FiniteMachine::SUCCEEDED)
    expect(fsm.drive).to eql(FiniteMachine::CANCELLED)
    expect(fsm.stop).to eql(FiniteMachine::SUCCEEDED)
    expect(fsm.stop).to eql(FiniteMachine::NOTRANSITION)
  end

  it "allows for self transition events" do
    digits = []
    callbacks = []
    phone = FiniteMachine.define do
      initial :on_hook

      events {
        event :digit,    :on_hook => :dialing
        event :digit,    :dialing => :dialing
        event :off_hook, :dialing => :alerting
      }

      callbacks {
        on_before_digit { |event, digit| digits << digit}
        on_before_off_hook { |event| callbacks << "dialing #{digits.join}" }
      }
    end

    expect(phone.current).to eq(:on_hook)
    phone.digit(9)
    expect(phone.current).to eq(:dialing)
    phone.digit(1)
    expect(phone.current).to eq(:dialing)
    phone.digit(1)
    expect(phone.current).to eq(:dialing)
    phone.off_hook
    expect(phone.current).to eq(:alerting)
    expect(digits).to match_array(digits)
    expect(callbacks).to match_array(["dialing 911"])
  end

  it "detects dangerous event names" do
    expect { FiniteMachine.define do
      events {
        event :transition, :a => :b
      }
    end }.to raise_error(FiniteMachine::AlreadyDefinedError)
  end
end
