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
    expect(fsm.finished?).to be(false)

    fsm.slow
    expect(fsm.current).to eql(:yellow)
    expect(fsm.finished?).to be(false)

    fsm.stop
    expect(fsm.current).to eql(:red)
    expect(fsm.finished?).to be(true)
  end

  it "allows to specify terminal state as parameter" do
    fsm = FiniteMachine.define terminal: :red do
      initial :green

      events {
        event :slow, :green  => :yellow
        event :stop, :yellow => :red
      }
    end
    fsm.slow
    fsm.stop
    expect(fsm.finished?).to be(true)
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
    expect(fsm.finished?).to be(false)

    fsm.slow
    expect(fsm.current).to eql(:yellow)
    expect(fsm.finished?).to be(false)

    fsm.stop
    expect(fsm.current).to eql(:red)
    expect(fsm.finished?).to be(false)
  end
end
