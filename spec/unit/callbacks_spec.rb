# encoding: utf-8

require 'spec_helper'

RSpec.describe FiniteMachine, 'callbacks' do

  it "triggers default init event" do
    called = []
    fsm = FiniteMachine.define do
      initial :green, defer: true, silent: false

      callbacks {
        # generic state callbacks
        on_enter      do |event| called << 'on_enter' end
        on_transition do |event| called << 'on_transition' end
        on_exit       do |event| called << 'on_exit' end

        # generic event callbacks
        on_before do |event| called << 'on_before' end
        on_after  do |event| called << 'on_after' end

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
      'on_before_init',
      'on_before',
      'on_exit_none',
      'on_exit',
      'on_transition_green',
      'on_transition',
      'on_enter_green',
      'on_enter',
      'on_after_init',
      'on_after'
    ])
  end

  it "executes callbacks in order" do
    called = []
    fsm = FiniteMachine.define do
      initial :green, silent: false

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

        on_before do |event| called << 'on_before' end
        on_after  do |event| called << 'on_after' end

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

    expect(fsm.current).to eq(:green)
    expect(called).to eq([
      'on_before',
      'on_exit',
      'on_transition_green',
      'on_transition',
      'on_enter_green',
      'on_enter',
      'on_after'
    ])

    called = []
    fsm.slow
    expect(called).to eql([
      'on_before_slow',
      'on_before',
      'on_exit_green',
      'on_exit',
      'on_transition_yellow',
      'on_transition',
      'on_enter_yellow',
      'on_enter',
      'on_after_slow',
      'on_after'
    ])

    called = []
    fsm.stop
    expect(called).to eql([
      'on_before_stop',
      'on_before',
      'on_exit_yellow',
      'on_exit',
      'on_transition_red',
      'on_transition',
      'on_enter_red',
      'on_enter',
      'on_after_stop',
      'on_after'
    ])

    called = []
    fsm.ready
    expect(called).to eql([
      'on_before_ready',
      'on_before',
      'on_exit_red',
      'on_exit',
      'on_transition_yellow',
      'on_transition',
      'on_enter_yellow',
      'on_enter',
      'on_after_ready',
      'on_after'
    ])

    called = []
    fsm.go
    expect(called).to eql([
      'on_before_go',
      'on_before',
      'on_exit_yellow',
      'on_exit',
      'on_transition_green',
      'on_transition',
      'on_enter_green',
      'on_enter',
      'on_after_go',
      'on_after'
    ])
  end

  it "maintains transition execution sequence from UML statechart" do
    called = []
    fsm = FiniteMachine.define do
      initial :previous, silent: false

      events {
        event :go, :previous => :next, if: -> { called << 'guard'; true}
      }

      callbacks {
        on_exit   { |event| called << "exit_#{event.from}" }
        on_before { |event| called << "before_#{event.name}" }
        on_transition { |event| called << "transition_#{event.from}_#{event.to}"}
        on_enter  { |event| called << "enter_#{event.to}"}
        on_after  { |event| called << "after_#{event.name}" }
      }
    end
    expect(fsm.current).to eq(:previous)
    fsm.go
    expect(called).to eq([
      'before_init',
      'exit_none',
      'transition_none_previous',
      'enter_previous',
      'after_init',
      'before_go',
      'guard',
      'exit_previous',
      'transition_previous_next',
      'enter_next',
      'after_go'
    ])
  end

  it "allows multiple callbacks for the same state" do
    called = []
    fsm = FiniteMachine.define do
      initial :green, silent: false

      events {
        event :slow,  :green  => :yellow
        event :stop,  :yellow => :red
        event :ready, :red    => :yellow
        event :go,    :yellow => :green
      }

      callbacks {
        # generic state callbacks
        on_enter      do |event| called << 'on_enter' end
        on_transition do |event| called << 'on_transition' end
        on_exit       do |event| called << 'on_exit' end

        # generic event callbacks
        on_before do |event| called << 'on_before' end
        on_after  do |event| called << 'on_after' end

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

    expect(fsm.current).to eql(:green)
    expect(called).to eql([
      'on_before',
      'on_exit',
      'on_transition',
      'on_enter',
      'on_after'
    ])
    called = []
    fsm.slow
    expect(fsm.current).to eql(:yellow)
    expect(called).to eql([
      'on_before_slow_1',
      'on_before_slow_2',
      'on_before',
      'on_exit_green_1',
      'on_exit_green_2',
      'on_exit',
      'on_transition_yellow_1',
      'on_transition_yellow_2',
      'on_transition',
      'on_enter_yellow_1',
      'on_enter_yellow_2',
      'on_enter',
      'on_after_slow_1',
      'on_after_slow_2',
      'on_after'
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
      'on_before_slow',
      'on_exit_green',
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
      target.expect(event.from).to target.eql(expected[:from])
      target.expect(event.to).to target.eql(expected[:to])
      target.expect(event.name).to target.eql(expected[:name])
      target.expect(a).to target.eql(expected[:a])
      target.expect(b).to target.eql(expected[:b])
      target.expect(c).to target.eql(expected[:c])
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
        on_enter(&callback)
        on_transition(&callback)
        on_exit(&callback)

        # generic event callbacks
        on_before(&callback)
        on_after(&callback)

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

  it "sets callback parameters correctly for transition from :any state" do
    expected = {name: :init, from: :none, to: :green, a: nil, b: nil, c: nil }

    callback = Proc.new { |event, a, b, c|
      target.expect(event.from).to target.eql(expected[:from])
      target.expect(event.to).to target.eql(expected[:to])
      target.expect(event.name).to target.eql(expected[:name])
      target.expect(a).to target.eql(expected[:a])
      target.expect(b).to target.eql(expected[:b])
      target.expect(c).to target.eql(expected[:c])
    }

    context = self

    fsm = FiniteMachine.define do
      initial :red

      target context

      events {
        event :power_on,  :off => :red
        event :power_off, :any => :off
        event :go,   :red    => :green
        event :slow, :green  => :yellow
        event :stop, :yellow => :red
      }

      callbacks {
        # generic state callbacks
        on_enter(&callback)
        on_transition(&callback)
        on_exit(&callback)

        # generic event callbacks
        on_before(&callback)
        on_after(&callback)

        # state callbacks
        on_enter :green,  &callback
        on_enter :yellow, &callback
        on_enter :red,    &callback
        on_enter :off,    &callback
        on_enter :off,    &callback

        on_transition :green,  &callback
        on_transition :yellow, &callback
        on_transition :red,    &callback
        on_transition :off,    &callback
        on_transition :off,    &callback

        on_exit :green,  &callback
        on_exit :yellow, &callback
        on_exit :red,    &callback
        on_exit :off,    &callback
        on_exit :off,    &callback

        # event callbacks
        on_before :power_on, &callback
        on_before :power_off, &callback
        on_before :go,       &callback
        on_before :slow,     &callback
        on_before :stop,     &callback

        on_after :power_on, &callback
        on_after :power_off, &callback
        on_after :go,       &callback
        on_after :slow,     &callback
        on_after :stop,     &callback
      }
    end

    expect(fsm.current).to eq(:red)

    expected = {name: :go, from: :red, to: :green, a: 1, b: 2, c: 3 }
    fsm.go(1, 2, 3)

    expected = {name: :slow, from: :green, to: :yellow, a: 4, b: 5, c: 6}
    fsm.slow(4, 5, 6)

    expected = {name: :stop, from: :yellow, to: :red, a: 7, b: 8, c: 9}
    fsm.stop(7, 8, 9)

    expected = {name: :power_off, from: :red, to: :off, a: 10, b: 11, c: 12}
    fsm.power_off(10, 11, 12)
  end

  it "raises an error with invalid callback name" do
    expect {
      FiniteMachine.define do
        initial :green

        events {
          event :slow, :green => :yellow
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
        events { event :slow, :green => :yellow }

        callbacks { on_before_green do |event| end }
      end
    }.to raise_error(FiniteMachine::InvalidCallbackNameError, '"on_before" callback is an event listener and cannot be used with "green" state name. Please use on_enter, on_transition or on_exit instead.')
  end

  it "propagates exceptions raised inside callback" do
    fsm = FiniteMachine.define do
      initial :green

      events { event :slow, :green => :yellow }

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
      initial :green, silent: false

      events {
        event :slow, :green  => :yellow
        event :go,   :yellow => :green
      }

      callbacks {
        # state callbacks
        once_on_enter_green  do |event| called << 'once_on_enter_green' end
        once_on_enter_yellow do |event| called << 'once_on_enter_yellow' end

        once_on_transition_green do |event| called << 'once_on_transition_green' end
        once_on_transition_yellow do |event| called << 'once_on_transition_yellow' end
        once_on_exit_none   do |event| called << 'once_on_exit_none' end
        once_on_exit_green  do |event| called << 'once_on_exit_green' end
        once_on_exit_yellow do |event| called << 'once_on_exit_yellow' end

        # event callbacks
        once_on_before_init do |event| called << 'once_on_before_init' end
        once_on_before_slow do |event| called << 'once_on_before_slow' end
        once_on_before_go   do |event| called << 'once_on_before_go' end

        once_on_after_init do |event| called << 'once_on_after_init' end
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
      'once_on_before_init',
      'once_on_exit_none',
      'once_on_transition_green',
      'once_on_enter_green',
      'once_on_after_init',
      'once_on_before_slow',
      'once_on_exit_green',
      'once_on_transition_yellow',
      'once_on_enter_yellow',
      'once_on_after_slow',
      'once_on_before_go',
      'once_on_exit_yellow',
      'once_on_after_go'
    ])
  end

  it "cancels transition on state callback" do
    fsm = FiniteMachine.define do
      initial :green

      events {
        event :slow, :green  => :yellow
        event :go,   :yellow => :green
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
        event :slow, :green  => :yellow
        event :go,   :yellow => :green
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
      initial :initial, silent: false

      events {
        event :bump, :initial => :low
        event :bump, :low     => :medium
        event :bump, :medium  => :high
      }

      callbacks {
        on_enter do |event|
          callbacks << "enter_#{event.name}_#{event.from}_#{event.to}"
        end
        on_exit do |event|
          callbacks << "exit_#{event.name}_#{event.from}_#{event.to}"
        end
        on_before do |event|
          callbacks << "before_#{event.name}_#{event.from}_#{event.to}"
        end
        on_after do |event|
          callbacks << "after_#{event.name}_#{event.from}_#{event.to}"
        end
      }
    end
    expect(fsm.current).to eq(:initial)
    fsm.bump
    expect(callbacks).to eq([
      'before_init_none_initial',
      'exit_init_none_initial',
      'enter_init_none_initial',
      'after_init_none_initial',
      'before_bump_initial_low',
      'exit_bump_initial_low',
      'enter_bump_initial_low',
      'after_bump_initial_low'
    ])
    fsm.bump
    expect(callbacks).to eq([
      'before_init_none_initial',
      'exit_init_none_initial',
      'enter_init_none_initial',
      'after_init_none_initial',
      'before_bump_initial_low',
      'exit_bump_initial_low',
      'enter_bump_initial_low',
      'after_bump_initial_low',
      'before_bump_low_medium',
      'exit_bump_low_medium',
      'enter_bump_low_medium',
      'after_bump_low_medium'
    ])
    fsm.bump
    expect(callbacks).to eq([
      'before_init_none_initial',
      'exit_init_none_initial',
      'enter_init_none_initial',
      'after_init_none_initial',
      'before_bump_initial_low',
      'exit_bump_initial_low',
      'enter_bump_initial_low',
      'after_bump_initial_low',
      'before_bump_low_medium',
      'exit_bump_low_medium',
      'enter_bump_low_medium',
      'after_bump_low_medium',
      'before_bump_medium_high',
      'exit_bump_medium_high',
      'enter_bump_medium_high',
      'after_bump_medium_high'
    ])
  end

  it "groups states under event name" do
    callbacks = []
    fsm = FiniteMachine.define do
      initial :initial, silent: false

      events {
        event :bump, :initial => :low,
                     :low     => :medium,
                     :medium  => :high
      }

      callbacks {
        on_enter do |event|
          callbacks << "enter_#{event.name}_#{event.from}_#{event.to}"
        end
        on_before do |event|
          callbacks << "before_#{event.name}_#{event.from}_#{event.to}"
        end
      }
    end
    expect(fsm.current).to eq(:initial)
    fsm.bump
    expect(callbacks).to eq([
      'before_init_none_initial',
      'enter_init_none_initial',
      'before_bump_initial_low',
      'enter_bump_initial_low'
    ])
    fsm.bump
    expect(callbacks).to eq([
      'before_init_none_initial',
      'enter_init_none_initial',
      'before_bump_initial_low',
      'enter_bump_initial_low',
      'before_bump_low_medium',
      'enter_bump_low_medium'
    ])
    fsm.bump
    expect(callbacks).to eq([
      'before_init_none_initial',
      'enter_init_none_initial',
      'before_bump_initial_low',
      'enter_bump_initial_low',
      'before_bump_low_medium',
      'enter_bump_low_medium',
      'before_bump_medium_high',
      'enter_bump_medium_high'
    ])
  end

  it "permits state and event with the same name" do
    called = []
    fsm = FiniteMachine.define do
      initial :on_hook, silent: false

      events {
        event :off_hook, :on_hook => :off_hook
        event :on_hook,  :off_hook => :on_hook
      }

      callbacks {
        on_before(:on_hook) { |event| called << "on_before_#{event.name}"}
        on_enter(:on_hook)  { |event| called << "on_enter_#{event.to}"}
      }
    end
    expect(fsm.current).to eq(:on_hook)
    expect(called).to eq([
      'on_enter_on_hook'
    ])
    fsm.off_hook
    expect(fsm.current).to eq(:off_hook)
    fsm.on_hook
    expect(called).to eq([
      'on_enter_on_hook',
      'on_before_on_hook',
      'on_enter_on_hook'
    ]);
  end

  it "allows to selectively silence events" do
    called = []
    fsm = FiniteMachine.define do
      initial :yellow

      events {
        event :go,   :yellow => :green, silent: true
        event :stop, :green  => :red
      }

      callbacks {
        on_enter :green do |event| called << 'on_enter_yellow' end
        on_enter :red   do |event| called << 'on_enter_red' end
      }
    end
    expect(fsm.current).to eq(:yellow)
    fsm.go
    fsm.stop
    expect(called).to eq(['on_enter_red'])
  end

  it "executes event-based callbacks even when state does not change" do
    called = []
    fsm = FiniteMachine.define do
      initial :active

      events {
        event :advance, active: :inactive, if: -> { false }
        event :advance, inactive: :active, if: -> { false }
      }

      callbacks {
        on_before do |event|
          called << "before_#{event.name}_#{event.from}_#{event.to}"
        end
        on_after do |event|
          called << "after_#{event.name}_#{event.from}_#{event.to}"
        end
      }
    end
    fsm.advance
    expect(called).to eq([
      'before_advance_active_inactive',
      'after_advance_active_inactive'
    ])
  end
end
