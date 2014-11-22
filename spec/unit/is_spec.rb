# encoding: utf-8

require 'spec_helper'

RSpec.describe FiniteMachine, 'is?' do

  it "allows to check if state is reachable" do
    fsm = FiniteMachine.define do
      initial :green

      events {
        event :slow,  :green  => :yellow
        event :stop,  :yellow => :red
        event :ready, :red    => :yellow
        event :go,    :yellow => :green
      }
    end

    expect(fsm.current).to eql(:green)

    expect(fsm.is?(:green)).to be true
    expect(fsm.is?(:yellow)).to be false
    expect(fsm.is?([:green,  :red])).to be true
    expect(fsm.is?([:yellow, :red])).to be false

    fsm.slow

    expect(fsm.is?(:green)).to be false
    expect(fsm.is?(:yellow)).to be true
    expect(fsm.is?([:green, :red])).to be false
    expect(fsm.is?([:yellow, :red])).to be true
  end

  it "defines helper methods to check current state" do
    fsm = FiniteMachine.define do
      initial :green

      events {
        event :slow,  :green  => :yellow
        event :stop,  :yellow => :red
        event :ready, :red    => :yellow
        event :go,    :yellow => :green
      }
    end
    expect(fsm.current).to eql(:green)

    expect(fsm.green?).to be true
    expect(fsm.yellow?).to be false

    fsm.slow

    expect(fsm.green?).to be false
    expect(fsm.yellow?).to be true
  end
end
