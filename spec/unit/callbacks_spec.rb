# encoding: utf-8

require 'spec_helper'

describe FiniteMachine, 'callbacks' do

  it "triggers default init event" do
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
        on_enter       do |event| called << 'on_enter' end
        on_enter_state do |event| called << 'on_enter_state' end
        on_enter_event do |event| called << 'on_enter_event' end

        on_transition       do |event| called << 'on_transition' end
        on_transition_state do |event| called << 'on_transition_state' end
        on_transition_event do |event| called << 'on_transition_event' end

        on_exit       do |event| called << 'on_exit' end
        on_exit_state do |event| called << 'on_exit_state' end
        on_exit_event do |event| called << 'on_exit_event' end

        # state callbacks
        on_enter :none  do |event| called << 'on_enter_none' end
        on_enter :green do |event| called << 'on_enter_green' end

        on_transition :none  do |event| called << 'on_transition_none' end
        on_transition :green do |event| called << 'on_transition_green' end

        on_exit :none  do |event| called << 'on_exit_none' end
        on_exit :green do |event| called << 'on_exit_green' end

        # event callbacks
        on_enter      :init do |event| called << 'on_enter_init' end
        on_transition :init do |event| called << 'on_transition_init' end
        on_exit       :init do |event| called << 'on_exit_init' end
      }
    end

    expect(fsm.current).to eql(:green)

    expect(called).to eql([
      'on_exit_none',
      'on_exit',
      'on_exit_state',
      'on_enter_init',
      'on_enter',
      'on_enter_event',
      'on_transition_green',
      'on_transition',
      'on_transition_state',
      'on_transition_init',
      'on_transition',
      'on_transition_event',
      'on_enter_green',
      'on_enter',
      'on_enter_state',
      'on_exit_init',
      'on_exit',
      'on_exit_event'
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
        on_enter       do |event| called << 'on_enter' end
        on_enter_state do |event| called << 'on_enter_state' end
        on_enter_event do |event| called << 'on_enter_event' end

        on_transition       do |event| called << 'on_transition' end
        on_transition_state do |event| called << 'on_transition_state' end
        on_transition_event do |event| called << 'on_transition_event' end

        on_exit       do |event| called << 'on_exit' end
        on_exit_state do |event| called << 'on_exit_state' end
        on_exit_event do |event| called << 'on_exit_event' end

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
        on_enter :slow  do |event| called << 'on_enter_slow' end
        on_enter :stop  do |event| called << "on_enter_stop" end
        on_enter :ready do |event| called << "on_enter_ready" end
        on_enter :go    do |event| called << "on_enter_go" end

        on_transition :slow  do |event| called << 'on_transition_slow' end
        on_transition :stop  do |event| called << "on_transition_stop" end
        on_transition :ready do |event| called << "on_transition_ready" end
        on_transition :go    do |event| called << "on_transition_go" end

        on_exit :slow  do |event| called << 'on_exit_slow' end
        on_exit :stop  do |event| called << "on_exit_stop" end
        on_exit :ready do |event| called << "on_exit_ready" end
        on_exit :go    do |event| called << "on_exit_go" end
      }
    end

    called = []
    fsm.slow
    expect(called).to eql([
      'on_exit_green',
      'on_exit',
      'on_exit_state',
      'on_enter_slow',
      'on_enter',
      'on_enter_event',
      'on_transition_yellow',
      'on_transition',
      'on_transition_state',
      'on_transition_slow',
      'on_transition',
      'on_transition_event',
      'on_enter_yellow',
      'on_enter',
      'on_enter_state',
      'on_exit_slow',
      'on_exit',
      'on_exit_event'
    ])

    called = []
    fsm.stop
    expect(called).to eql([
      'on_exit_yellow',
      'on_exit',
      'on_exit_state',
      'on_enter_stop',
      'on_enter',
      'on_enter_event',
      'on_transition_red',
      'on_transition',
      'on_transition_state',
      'on_transition_stop',
      'on_transition',
      'on_transition_event',
      'on_enter_red',
      'on_enter',
      'on_enter_state',
      'on_exit_stop',
      'on_exit',
      'on_exit_event'
    ])

    called = []
    fsm.ready
    expect(called).to eql([
      'on_exit_red',
      'on_exit',
      'on_exit_state',
      'on_enter_ready',
      'on_enter',
      'on_enter_event',
      'on_transition_yellow',
      'on_transition',
      'on_transition_state',
      'on_transition_ready',
      'on_transition',
      'on_transition_event',
      'on_enter_yellow',
      'on_enter',
      'on_enter_state',
      'on_exit_ready',
      'on_exit',
      'on_exit_event'
    ])

    called = []
    fsm.go
    expect(called).to eql([
      'on_exit_yellow',
      'on_exit',
      'on_exit_state',
      'on_enter_go',
      'on_enter',
      'on_enter_event',
      'on_transition_green',
      'on_transition',
      'on_transition_state',
      'on_transition_go',
      'on_transition',
      'on_transition_event',
      'on_enter_green',
      'on_enter',
      'on_enter_state',
      'on_exit_go',
      'on_exit',
      'on_exit_event'
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
        # generic callbacks
        on_enter      do |event| called << 'on_enter' end
        on_transition do |event| called << 'on_transition' end
        on_exit       do |event| called << 'on_exit' end

        # state callbacks
        on_exit :green do |event| called << 'on_exit_green_1' end
        on_exit :green do |event| called << 'on_exit_green_2' end
        on_enter :yellow do |event| called << 'on_enter_yellow_1' end
        on_enter :yellow do |event| called << 'on_enter_yellow_2' end
        on_transition :yellow do |event| called << 'on_transition_yellow_1' end
        on_transition :yellow do |event| called << 'on_transition_yellow_2' end

        # event callbacks
        on_enter      :slow do |event| called << 'on_enter_slow_1' end
        on_enter      :slow do |event| called << 'on_enter_slow_2' end
        on_transition :slow do |event| called << 'on_transition_slow_1' end
        on_transition :slow do |event| called << 'on_transition_slow_2' end
        on_exit       :slow do |event| called << 'on_exit_slow_1' end
        on_exit       :slow do |event| called << 'on_exit_slow_2' end
      }
    end

    called = []
    fsm.slow
    expect(fsm.current).to eql(:yellow)
    expect(called).to eql([
      'on_exit_green_1',
      'on_exit_green_2',
      'on_exit',
      'on_enter_slow_1',
      'on_enter_slow_2',
      'on_enter',
      'on_transition_yellow_1',
      'on_transition_yellow_2',
      'on_transition',
      'on_transition_slow_1',
      'on_transition_slow_2',
      'on_transition',
      'on_enter_yellow_1',
      'on_enter_yellow_2',
      'on_enter',
      'on_exit_slow_1',
      'on_exit_slow_2',
      'on_exit'
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
        on_enter_slow do |event| called << 'on_enter_slow' end
        on_transition_slow do |event| called << 'on_transition_slow' end
        on_exit_slow do |event| called << 'on_exit_slow' end
      }
    end

    called = []
    fsm.slow
    expect(fsm.current).to eql(:yellow)
    expect(called).to eql([
      'on_exit_green',
      'on_enter_slow',
      'on_transition_yellow',
      'on_transition_slow',
      'on_enter_yellow',
      'on_exit_slow'
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
        # generic callbacks
        on_enter      &callback
        on_transition &callback
        on_exit       &callback

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
        on_enter :slow , &callback
        on_enter :stop , &callback
        on_enter :ready, &callback
        on_enter :go   , &callback

        on_transition :slow , &callback
        on_transition :stop , &callback
        on_transition :ready, &callback
        on_transition :go   , &callback

        on_exit :slow , &callback
        on_exit :stop , &callback
        on_exit :ready, &callback
        on_exit :go   , &callback
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
    }.to raise_error(FiniteMachine::InvalidCallbackNameError, /magic is not a valid callback name/)
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
        on_enter_stop do |event|
          called << 'on_enter_stop'
        end
      }
    end
    expect(fsm.current).to eql(:green)
    fsm.stop
    expect(fsm.current).to eql(:yellow)
    fsm.stop
    expect(fsm.current).to eql(:red)
    expect(called).to eql([
      'on_enter_stop',
      'on_enter_stop'
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
        once_on_enter_green  do |event| called << 'once_on_enter_green' end
        once_on_enter_yellow do |event| called << 'once_on_enter_yellow' end

        once_on_transition_green do |event| called << 'once_on_transition_green' end
        once_on_transition_yellow do |event| called << 'once_on_transition_yellow' end

        once_on_exit_green  do |event| called << 'once_on_exit_green' end
        once_on_exit_yellow do |event| called << 'once_on_exit_yellow' end
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
      'once_on_transition_green',
      'once_on_enter_green',
      'once_on_exit_green',
      'once_on_transition_yellow',
      'once_on_enter_yellow',
      'once_on_exit_yellow'
    ])
  end
end
