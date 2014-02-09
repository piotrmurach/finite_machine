# encoding: utf-8

require 'spec_helper'

describe FiniteMachine, 'finished?' do

  it "allows to specify terminal state" do
    fsm = FiniteMachine.define do
      initial :green
      terminal :red

      events {
        event :slow, :green  => :yellow
        event :stop, :yellow => :red
      }
    end

    expect(fsm.current).to eql(:green)
    expect(fsm.finished?).to be_false

    fsm.slow
    expect(fsm.current).to eql(:yellow)
    expect(fsm.finished?).to be_false

    fsm.stop
    expect(fsm.current).to eql(:red)
    expect(fsm.finished?).to be_true
  end

  it "checks without terminal state" do
    fsm = FiniteMachine.define do
      initial :green

      events {
        event :slow, :green  => :yellow
        event :stop, :yellow => :red
      }
    end

    expect(fsm.current).to eql(:green)
    expect(fsm.finished?).to be_false

    fsm.slow
    expect(fsm.current).to eql(:yellow)
    expect(fsm.finished?).to be_false

    fsm.stop
    expect(fsm.current).to eql(:red)
    expect(fsm.finished?).to be_false
  end
end
