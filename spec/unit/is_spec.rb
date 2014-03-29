# encoding: utf-8

require 'spec_helper'

describe FiniteMachine, 'is?' do

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

    expect(fsm.is?(:green)).to be_true
    expect(fsm.is?(:yellow)).to be_false
    expect(fsm.is?([:green,  :red])).to be_true
    expect(fsm.is?([:yellow, :red])).to be_false

    fsm.slow

    expect(fsm.is?(:green)).to be_false
    expect(fsm.is?(:yellow)).to be_true
    expect(fsm.is?([:green, :red])).to be_false
    expect(fsm.is?([:yellow, :red])).to be_true
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

    expect(fsm.green?).to be_true
    expect(fsm.yellow?).to be_false

    fsm.slow

    expect(fsm.green?).to be_false
    expect(fsm.yellow?).to be_true
  end
end
