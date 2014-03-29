# encoding: utf-8

require 'spec_helper'

describe FiniteMachine, 'async_events' do

  it 'runs events asynchronously' do
    called = []
    fsm = FiniteMachine.define do
      initial :green

      events {
        event :slow, :green => :yellow
        event :stop, :yellow => :red
        event :ready, :red    => :yellow
        event :go,    :yellow => :green
      }

      callbacks {
        on_enter :yellow do |event, a| called << "on_enter_yellow_#{a}" end
        on_enter :red    do |event, a| called << "on_enter_red_#{a}" end
      }
    end

    expect(fsm.current).to eql(:green)
    fsm.async.slow(:foo)
    FiniteMachine.event_queue.join 0.01
    expect(fsm.current).to eql(:yellow)
    expect(called).to eql([
      'on_enter_yellow_foo'
    ])
    fsm.async.stop(:bar)
    FiniteMachine.event_queue.join 0.01
    expect(fsm.current).to eql(:red)
    expect(called).to eql([
      'on_enter_yellow_foo',
      'on_enter_red_bar'
    ])
  end
end
