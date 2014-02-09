# encoding: utf-8

require 'spec_helper'

describe FiniteMachine, 'initialize' do

  it "defaults initial state to :none" do
    fsm = FiniteMachine.define do
      events {
        event :slow, :green  => :yellow
        event :stop, :yellow => :red
      }
    end

    expect(fsm.current).to eql(:none)
  end

  it "allows to specify inital state" do
    fsm = FiniteMachine.define do
      initial :green

      events {
        event :slow, :green  => :yellow
        event :stop, :yellow => :red
      }
    end

    expect(fsm.current).to eql(:green)
  end

  it "allows to specify deferred inital state" do
    fsm = FiniteMachine.define do
      initial state: :green, defer: true

      events {
        event :slow, :green  => :yellow
        event :stop, :yellow => :red
      }
    end

    fsm.init
    expect(fsm.current).to eql(:green)
  end

  it "allows to specify inital start event" do
    fsm = FiniteMachine.define do
      initial state: :green, event: :start

      events {
        event :slow, :green  => :yellow
        event :stop, :yellow => :red
      }
    end

    expect(fsm.current).to eql(:none)
    fsm.start
    expect(fsm.current).to eql(:green)
  end
end
