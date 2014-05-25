# encoding: utf-8

require 'spec_helper'

describe FiniteMachine, 'callbacks' do

  it "triggers default init event" do
    called = []
    fsm = FiniteMachine.define do
      initial state: :green, defer: true

      callbacks {
        # generic state callbacks
        on_enter_state      do |event| called << 'on_enter_state' end
        on_transition_state do |event| called << 'on_transition_state' end
        on_exit_state       do |event| called << 'on_exit_state' end

        # generic event callbacks
        on_before_event do |event| called << 'on_before_event' end
        on_after_event  do |event| called << 'on_after_event' end

        # state callbacks
        on_enter :none  do |event| called << 'on_enter_none' end
        on_enter :green do |event| called << 'on_enter_green' end

        on_transition :none  do |event| called << 'on_transition_none' end
        on_transition :green do |event| called << 'on_transition_green' end

        on_exit :none  do |event| called << 'on_exit_none' end
        on_exit :green do |event| called << 'on_exit_green' end

        # event callbacks
        on_before :init do |event| called << 'on_before_init' end
        on_after  :init do |event| called << 'on_after_init' end
      }
    end

    expect(fsm.current).to eql(:none)
    fsm.init
    expect(called).to eql([
      'on_exit_none',
      'on_exit_state',
      'on_before_init',
      'on_before_event',
      'on_transition_green',
      'on_transition_state',
      'on_enter_green',
      'on_enter_state',
      'on_after_init',
      'on_after_event'
    ])
  end

  it "executes callbacks in order" do
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
        # generic callbacks
        on_enter_state      do |event| called << 'on_enter_state' end
        on_transition_state do |event| called << 'on_transition_state' end
        on_exit_state       do |event| called << 'on_exit_state' end

        on_before_event do |event| called << 'on_before_event' end
        on_after_event  do |event| called << 'on_after_event' end

        # state callbacks
        on_enter :green  do |event| called << 'on_enter_green' end
        on_enter :yellow do |event| called << "on_enter_yellow" end
        on_enter :red    do |event| called << "on_enter_red" end

        on_transition :green  do |event| called << 'on_transition_green' end
        on_transition :yellow do |event| called << "on_transition_yellow" end
        on_transition :red    do |event| called << "on_transition_red" end

        on_exit :green  do |event| called << 'on_exit_green' end
        on_exit :yellow do |event| called << "on_exit_yellow" end
        on_exit :red    do |event| called << "on_exit_red" end

        # event callbacks
        on_before :slow  do |event| called << 'on_before_slow' end
        on_before :stop  do |event| called << "on_before_stop" end
        on_before :ready do |event| called << "on_before_ready" end
        on_before :go    do |event| called << "on_before_go" end

        on_after :slow  do |event| called << 'on_after_slow' end
        on_after :stop  do |event| called << "on_after_stop" end
        on_after :ready do |event| called << "on_after_ready" end
        on_after :go    do |event| called << "on_after_go" end
      }
    end

    called = []
    fsm.slow
    expect(called).to eql([
      'on_exit_green',
      'on_exit_state',
      'on_before_slow',
      'on_before_event',
      'on_transition_yellow',
      'on_transition_state',
      'on_enter_yellow',
      'on_enter_state',
      'on_after_slow',
      'on_after_event'
    ])

    called = []
    fsm.stop
    expect(called).to eql([
      'on_exit_yellow',
      'on_exit_state',
      'on_before_stop',
      'on_before_event',
      'on_transition_red',
      'on_transition_state',
      'on_enter_red',
      'on_enter_state',
      'on_after_stop',
      'on_after_event'
    ])

    called = []
    fsm.ready
    expect(called).to eql([
      'on_exit_red',
      'on_exit_state',
      'on_before_ready',
      'on_before_event',
      'on_transition_yellow',
      'on_transition_state',
      'on_enter_yellow',
      'on_enter_state',
      'on_after_ready',
      'on_after_event'
    ])

    called = []
    fsm.go
    expect(called).to eql([
      'on_exit_yellow',
      'on_exit_state',
      'on_before_go',
      'on_before_event',
      'on_transition_green',
      'on_transition_state',
      'on_enter_green',
      'on_enter_state',
      'on_after_go',
      'on_after_event'
    ])
  end

  it "allows multiple callbacks for the same state" do
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
        # generic state callbacks
        on_enter_state      do |event| called << 'on_enter_state' end
        on_transition_state do |event| called << 'on_transition_state' end
        on_exit_state       do |event| called << 'on_exit_state' end

        # generic event callbacks
        on_before_event do |event| called << 'on_before_event' end
        on_after_event  do |event| called << 'on_after_event' end

        # state callbacks
        on_exit       :green  do |event| called << 'on_exit_green_1' end
        on_exit       :green  do |event| called << 'on_exit_green_2' end
        on_enter      :yellow do |event| called << 'on_enter_yellow_1' end
        on_enter      :yellow do |event| called << 'on_enter_yellow_2' end
        on_transition :yellow do |event| called << 'on_transition_yellow_1' end
        on_transition :yellow do |event| called << 'on_transition_yellow_2' end

        # event callbacks
        on_before :slow do |event| called << 'on_before_slow_1' end
        on_before :slow do |event| called << 'on_before_slow_2' end
        on_after  :slow do |event| called << 'on_after_slow_1' end
        on_after  :slow do |event| called << 'on_after_slow_2' end
      }
    end

    called = []
    fsm.slow
    expect(fsm.current).to eql(:yellow)
    expect(called).to eql([
      'on_exit_green_1',
      'on_exit_green_2',
      'on_exit_state',
      'on_before_slow_1',
      'on_before_slow_2',
      'on_before_event',
      'on_transition_yellow_1',
      'on_transition_yellow_2',
      'on_transition_state',
      'on_enter_yellow_1',
      'on_enter_yellow_2',
      'on_enter_state',
      'on_after_slow_1',
      'on_after_slow_2',
      'on_after_event'
    ])
  end

  it "allows for fluid callback definition" do
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
        # state callbacks
        on_exit_green do |event| called << 'on_exit_green' end
        on_enter_yellow do |event| called << 'on_enter_yellow' end
        on_transition_yellow do |event| called << 'on_transition_yellow' end

        # event callbacks
        on_before_slow do |event| called << 'on_before_slow' end
        on_after_slow do |event| called << 'on_after_slow' end
      }
    end

    called = []
    fsm.slow
    expect(fsm.current).to eql(:yellow)
    expect(called).to eql([
      'on_exit_green',
      'on_before_slow',
      'on_transition_yellow',
      'on_enter_yellow',
      'on_after_slow'
    ])
  end

  it "passes event object to callback" do
    evt = nil
    fsm = FiniteMachine.define do
      initial :green

      events {
        event :slow, :green  => :yellow
      }

      callbacks {
        on_enter(:yellow) { |e| evt = e }
      }
    end

    expect(fsm.current).to eql(:green)
    fsm.slow
    expect(fsm.current).to eql(:yellow)

    expect(evt.from).to eql(:green)
    expect(evt.to).to eql(:yellow)
    expect(evt.name).to eql(:slow)
  end

  it "identifies the from state for callback event parameter" do
    evt = nil
    fsm = FiniteMachine.define do
      initial :green

      events {
        event :slow, [:red, :blue, :green]  => :yellow
        event :fast, :red => :purple
      }

      callbacks {
        on_enter(:yellow) { |e| evt = e }
      }
    end

    expect(fsm.current).to eql(:green)
    fsm.slow
    expect(fsm.current).to eql(:yellow)

    expect(evt.from).to eql(:green)
    expect(evt.to).to eql(:yellow)
    expect(evt.name).to eql(:slow)
  end

  it "passes extra parameters to callbacks" do
    expected = {name: :init, from: :none, to: :green, a: nil, b: nil, c: nil }

    callback = Proc.new { |event, a, b, c|
      expect(event.from).to eql(expected[:from])
      expect(event.to).to eql(expected[:to])
      expect(event.name).to eql(expected[:name])
      expect(a).to eql(expected[:a])
      expect(b).to eql(expected[:b])
      expect(c).to eql(expected[:c])
    }
    context = self

    fsm = FiniteMachine.define do
      initial :green

      target context

      events {
        event :slow,  :green  => :yellow
        event :stop,  :yellow => :red
        event :ready, :red    => :yellow
        event :go,    :yellow => :green
      }

      callbacks {
        # generic state callbacks
        on_enter_state(&callback)
        on_transition_state(&callback)
        on_exit_state(&callback)

        # generic event callbacks
        on_before_event(&callback)
        on_after_event(&callback)

        # state callbacks
        on_enter :green,  &callback
        on_enter :yellow, &callback
        on_enter :red,    &callback

        on_transition :green , &callback
        on_transition :yellow, &callback
        on_transition :red   , &callback

        on_exit :green , &callback
        on_exit :yellow, &callback
        on_exit :red   , &callback

        # event callbacks
        on_before :slow , &callback
        on_before :stop , &callback
        on_before :ready, &callback
        on_before :go   , &callback

        on_after :slow , &callback
        on_after :stop , &callback
        on_after :ready, &callback
        on_after :go   , &callback
      }
    end

    expected = {name: :slow, from: :green, to: :yellow, a: 1, b: 2, c: 3}
    fsm.slow(1, 2, 3)

    expected = {name: :stop, from: :yellow, to: :red, a: 'foo', b: 'bar'}
    fsm.stop('foo', 'bar')

    expected = {name: :ready, from: :red, to: :yellow, a: :foo, b: :bar}
    fsm.ready(:foo, :bar)

    expected = {name: :go, from: :yellow, to: :green, a: nil, b: nil}
    fsm.go(nil, nil)
  end

  it "raises an error with invalid callback name" do
    expect {
      FiniteMachine.define do
        initial :green

        events {
          event :slow,  :green  => :yellow
        }

        callbacks {
          on_enter(:magic) { |event| called << 'on_enter'}
        }
      end
    }.to raise_error(FiniteMachine::InvalidCallbackNameError, /\"magic\" is not a valid callback name/)
  end

  it "doesn't allow to mix state callback with event name" do
    expect {
      FiniteMachine.define do
        events { event :slow,  :green  => :yellow }

        callbacks { on_enter_slow do |event| end }
      end
    }.to raise_error(FiniteMachine::InvalidCallbackNameError, "\"on_enter\" callback is a state listener and cannot be used with \"slow\" event name. Please use on_before or on_after instead.")
  end

  it "doesn't allow to mix event callback with state name" do
    expect {
      FiniteMachine.define do
        events { event :slow,  :green  => :yellow }

        callbacks { on_before_green do |event| end }
      end
    }.to raise_error(FiniteMachine::InvalidCallbackNameError, '"on_before" callback is an event listener and cannot be used with "green" state name. Please use on_enter, on_transition or on_exit instead.')
  end

  it "propagates exceptions raised inside callback" do
    fsm = FiniteMachine.define do
      initial :green

      events { event :slow,  :green  => :yellow }

      callbacks { on_enter(:yellow) { raise RuntimeError } }
    end

    expect(fsm.current).to eql(:green)
    expect { fsm.slow }.to raise_error(RuntimeError)
  end

  it "executes callbacks with multiple 'from' transitions" do
    called = []
    fsm = FiniteMachine.define do
      initial :green

      events {
        event :stop,  :green  => :yellow
        event :stop,  :yellow => :red
      }

      callbacks {
        on_before_stop do |event|
          called << 'on_before_stop'
        end
      }
    end
    expect(fsm.current).to eql(:green)
    fsm.stop
    expect(fsm.current).to eql(:yellow)
    fsm.stop
    expect(fsm.current).to eql(:red)
    expect(called).to eql([
      'on_before_stop',
      'on_before_stop'
    ])
  end

  it "allows to define callbacks on machine instance" do
    called = []
    fsm = FiniteMachine.define do
      initial :green

      events {
        event :slow,  :green  => :yellow
        event :stop,  :yellow => :red
        event :ready, :red    => :yellow
        event :go,    :yellow => :green
      }
    end

    fsm.on_enter_yellow do |event|
      called << 'on_enter_yellow'
    end

    expect(fsm.current).to eql(:green)
    fsm.slow
    expect(called).to eql([
      'on_enter_yellow'
    ])
  end

  it "raises error for unknown callback" do
    expect { FiniteMachine.define do
      initial :green

      events {
        event :slow,  :green  => :yellow
        event :stop,  :yellow => :red
        event :ready, :red    => :yellow
        event :go,    :yellow => :green
      }

      callbacks {
        on_enter_unknown do |event| end
      }
    end }.to raise_error(NoMethodError)
  end

  it "triggers callbacks only once" do
    called = []
    fsm = FiniteMachine.define do
      initial :green

      events {
        event :slow,  :green  => :yellow
        event :go,    :yellow => :green
      }

      callbacks {
        # state callbacks
        once_on_enter_green  do |event| called << 'once_on_enter_green' end
        once_on_enter_yellow do |event| called << 'once_on_enter_yellow' end

        once_on_transition_green do |event| called << 'once_on_transition_green' end
        once_on_transition_yellow do |event| called << 'once_on_transition_yellow' end

        once_on_exit_green  do |event| called << 'once_on_exit_green' end
        once_on_exit_yellow do |event| called << 'once_on_exit_yellow' end

        # event callbacks
        once_on_before_slow do |event| called << 'once_on_before_slow' end
        once_on_before_go   do |event| called << 'once_on_before_go' end

        once_on_after_slow do |event| called << 'once_on_after_slow' end
        once_on_after_go   do |event| called << 'once_on_after_go' end
      }
    end
    expect(fsm.current).to eql(:green)
    fsm.slow
    expect(fsm.current).to eql(:yellow)
    fsm.go
    expect(fsm.current).to eql(:green)
    fsm.slow
    expect(fsm.current).to eql(:yellow)
    expect(called).to eql([
      'once_on_exit_green',
      'once_on_before_slow',
      'once_on_transition_yellow',
      'once_on_enter_yellow',
      'once_on_after_slow',
      'once_on_exit_yellow',
      'once_on_before_go',
      'once_on_transition_green',
      'once_on_enter_green',
      'once_on_after_go'
    ])
  end

  it "cancels transition on state callback" do
    fsm = FiniteMachine.define do
      initial :green

      events {
        event :slow,  :green  => :yellow
        event :go,    :yellow => :green
      }

      callbacks {
        on_exit :green do |event| FiniteMachine::CANCELLED end
      }
    end

    expect(fsm.current).to eql(:green)
    fsm.slow
    expect(fsm.current).to eql(:green)
  end

  it "cancels transition on event callback" do
    fsm = FiniteMachine.define do
      initial :green

      events {
        event :slow,  :green  => :yellow
        event :go,    :yellow => :green
      }

      callbacks {
        on_exit :green do |event|
          FiniteMachine::CANCELLED
        end
      }
    end

    expect(fsm.current).to eql(:green)
    fsm.slow
    expect(fsm.current).to eql(:green)
  end

  xit "groups callbacks"

  it "groups states from separate events with the same name" do
    callbacks = []
    fsm = FiniteMachine.define do
      initial :initial

      events {
        event :bump, :initial => :low
        event :bump, :low     => :medium
        event :bump, :medium  => :high
      }

      callbacks {
        on_enter_state do |event|
          callbacks << "enter_state_#{event.name}_#{event.from}_#{event.to}"
        end
        on_before_event do |event|
          callbacks << "before_event_#{event.name}_#{event.from}_#{event.to}"
        end
      }
    end
    expect(fsm.current).to eq(:initial)
    fsm.bump
    expect(callbacks).to eq([
      'before_event_bump_initial_low',
      'enter_state_bump_initial_low'
    ])
    fsm.bump
    expect(callbacks).to eq([
      'before_event_bump_initial_low',
      'enter_state_bump_initial_low',
      'before_event_bump_low_medium',
      'enter_state_bump_low_medium'
    ])
    fsm.bump
    expect(callbacks).to eq([
      'before_event_bump_initial_low',
      'enter_state_bump_initial_low',
      'before_event_bump_low_medium',
      'enter_state_bump_low_medium',
      'before_event_bump_medium_high',
      'enter_state_bump_medium_high'
    ])
  end

  it "groups states under event name" do
    callbacks = []
    fsm = FiniteMachine.define do
      initial :initial

      events {
        event :bump, :initial => :low,
                     :low     => :medium,
                     :medium  => :high
      }

      callbacks {
        on_enter_state do |event|
          callbacks << "enter_state_#{event.name}_#{event.from}_#{event.to}"
        end
        on_before_event do |event|
          callbacks << "before_event_#{event.name}_#{event.from}_#{event.to}"
        end
      }
    end
    expect(fsm.current).to eq(:initial)
    fsm.bump
    expect(callbacks).to eq([
      'before_event_bump_initial_low',
      'enter_state_bump_initial_low'
    ])
    fsm.bump
    expect(callbacks).to eq([
      'before_event_bump_initial_low',
      'enter_state_bump_initial_low',
      'before_event_bump_low_medium',
      'enter_state_bump_low_medium'
    ])
    fsm.bump
    expect(callbacks).to eq([
      'before_event_bump_initial_low',
      'enter_state_bump_initial_low',
      'before_event_bump_low_medium',
      'enter_state_bump_low_medium',
      'before_event_bump_medium_high',
      'enter_state_bump_medium_high'
    ])
  end
end
