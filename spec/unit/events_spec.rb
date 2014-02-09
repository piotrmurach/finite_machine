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

    expect(fsm.can?(:noop)).to be_true
    expect(fsm.can?(:slow)).to be_true

    fsm.noop
    expect(fsm.current).to eql(:green)
    fsm.slow
    expect(fsm.current).to eql(:yellow)

    expect(fsm.cannot?(:noop)).to be_true
    expect(fsm.cannot?(:slow)).to be_true
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

    expect { fsm.stop }.to raise_error(FiniteMachine::TransitionError, /state 'green'/)
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

      expect(fsm.can?(:slow)).to be_true
      expect(fsm.can?(:stop)).to be_true
      expect(fsm.cannot?(:ready)).to be_true
      expect(fsm.cannot?(:go)).to be_true

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

      expect(fsm.can?(:slow)).to be_true
      expect(fsm.can?(:stop)).to be_true
      expect(fsm.cannot?(:ready)).to be_true
      expect(fsm.cannot?(:go)).to be_true

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
      }
    end

    expect(fsm.current).to eql(:green)

    expect(fsm.can?(:stop)).to be_true

    fsm.stop
    expect(fsm.current).to eql(:yellow)
    fsm.stop
    expect(fsm.current).to eql(:red)
    fsm.stop
    expect(fsm.current).to eql(:pink)
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
        on_enter(:drive) { }
        on_exit(:stop)   { }
      }
    end

    expect(fsm.current).to eql(:neutral)
    expect(fsm.start).to eql(FiniteMachine::SUCCEEDED)
    expect(fsm.drive).to eql(FiniteMachine::CANCELLED)
    expect(fsm.stop).to eql(FiniteMachine::SUCCEEDED)
    expect(fsm.stop).to eql(FiniteMachine::NOTRANSITION)
  end
end
