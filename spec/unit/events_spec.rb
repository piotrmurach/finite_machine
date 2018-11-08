# frozen_string_literal: true

RSpec.describe FiniteMachine, 'events' do
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

  it "permits event from any state using :from" do
    fsm = FiniteMachine.define do
      initial :green

      events {
        event :slow,  from: :green,  to: :yellow
        event :stop,  from: :yellow, to: :red
        event :ready, from: :red,    to: :yellow
        event :go,    from: :yellow, to: :green
        event :run,   from: any_state, to: :green
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

  it "permits event from any state for hash syntax" do
    fsm = FiniteMachine.define do
      initial :red

      events {
        event :start, :red    => :yellow
        event :run,   :yellow => :green
        event :stop,  :green  => :red
        event :go,    any_state => :green
      }
    end

    expect(fsm.current).to eql(:red)

    fsm.go
    expect(fsm.current).to eql(:green)
    fsm.stop
    fsm.start
    expect(fsm.current).to eql(:yellow)
    fsm.go
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

  it "doesn't raise error on invalid transition for non-dangerous version" do
    called = []
    fsm = FiniteMachine.define do
      initial :green

      events {
        event :stop, from: :yellow, to: :red
      }
      callbacks {
        on_before :stop do |event| called << 'on_before_stop' end
        on_after  :stop do |event| called << 'on_before_stop' end
      }
    end

    expect(fsm.current).to eq(:green)
    expect(fsm.stop).to eq(false)
    expect(fsm.current).to eq(:green)
    expect(called).to match_array(['on_before_stop'])
  end

  context 'for non-dangerous version' do
    it "doesn't raise error on invalid transition and fires callbacks" do
      called = []
      fsm = FiniteMachine.define do
        initial :green

        events {
          event :stop, from: :yellow, to: :red
        }
        callbacks {
          on_before :stop do |event| called << 'on_before_stop' end
          on_after  :stop do |event| called << 'on_before_stop' end
        }
      end

      expect(fsm.current).to eq(:green)
      expect(fsm.stop).to eq(false)
      expect(fsm.current).to eq(:green)
      expect(called).to match_array(['on_before_stop'])
    end

    it "raises error on invalid transition for dangerous version" do
      called = []
      fsm = FiniteMachine.define do
        initial :green

        events {
          event :slow,  from: :green,  to: :yellow
          event :stop,  from: :yellow, to: :red, silent: true
        }
        callbacks {
          on_before :stop do |event| called << 'on_before_stop' end
          on_after  :stop do |event| called << 'on_before_stop' end
        }
      end

      expect(fsm.current).to eql(:green)
      expect(fsm.stop).to eq(false)
      expect(called).to match_array([])
    end
  end

  context 'for dangerous version' do
    it "raises error on invalid transition without callbacks" do
      called = []
      fsm = FiniteMachine.define do
        initial :green

        events {
          event :start, :red => :yellow, silent: true
        }
        callbacks {
          on_before :start do |event| called << 'on_before_start' end
          on_after  :start do |event| called << 'on_after_start' end
        }
      end

      expect(fsm.current).to eq(:green)
      expect { fsm.start! }.to raise_error(FiniteMachine::InvalidStateError)
      expect(called).to eq([])
      expect(fsm.current).to eq(:green)
    end

    it "raises error on invalid transition with callbacks fired" do
      called = []
      fsm = FiniteMachine.define do
        initial :green

        events {
          event :start, :red => :yellow
        }
        callbacks {
          on_before :start do |event| called << 'on_before_start' end
          on_after  :start do |event| called << 'on_after_start' end
        }
      end

      expect(fsm.current).to eq(:green)
      expect { fsm.start! }.to raise_error(FiniteMachine::InvalidStateError,
                                           /inappropriate current state 'green'/)
      expect(called).to eq(['on_before_start'])
      expect(fsm.current).to eq(:green)
    end
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
        event :stop,   any_state  => :neutral
      }

      callbacks {
        on_before(:drive) { cancel_event }
        on_after(:stop)   { }
      }
    end

    expect(fsm.current).to eql(:neutral)
    expect(fsm.start).to eql(true)
    expect(fsm.drive).to eql(false)
    expect(fsm.stop).to eql(true)
    expect(fsm.stop).to eql(true)
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

  it "executes event block" do
    fsm = FiniteMachine.define do
      initial :red

      events {
        event :start, :red => :green
        event :stop,  :green => :red
      }
    end

    expect(fsm.current).to eq(:red)
    called = []
    fsm.start do |from, to|
      called << "execute_start_#{from}_#{to}"
    end
    expect(called).to eq(['execute_start_red_green'])
  end
end
