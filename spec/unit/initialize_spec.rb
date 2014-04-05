# encoding: utf-8

require 'spec_helper'

describe FiniteMachine, 'initialize' do

  before(:each) {
    Logger = Class.new do
      attr_accessor :level

      def initialize
        @level = :pending
      end
    end
  }

  it "defaults initial state to :none" do
    fsm = FiniteMachine.define do
      events {
        event :slow, :green  => :yellow
        event :stop, :yellow => :red
      }
    end

    expect(fsm.current).to eql(:none)
  end

  it "requires initial state transition from :none" do
    fsm = FiniteMachine.define do
      events {
        event :init, :none   => :green
        event :slow, :green  => :yellow
        event :stop, :yellow => :red
      }
    end

    expect(fsm.current).to eql(:none)
    fsm.init
    expect(fsm.current).to eql(:green)
  end

  it "allows to specify inital state" do
    called = []
    fsm = FiniteMachine.define do
      initial :green

      events {
        event :slow, :green  => :yellow
        event :stop, :yellow => :red
      }
      callbacks {
        on_enter :green do |event| called << 'on_enter_green' end
      }
    end
    expect(fsm.current).to eql(:green)
    expect(called).to be_empty
  end

  it "allows to specify deferred inital state" do
    fsm = FiniteMachine.define do
      initial state: :green, defer: true

      events {
        event :slow, :green  => :yellow
        event :stop, :yellow => :red
      }
    end

    expect(fsm.current).to eql(:none)
    fsm.init
    expect(fsm.current).to eql(:green)
  end

  it "raises error when specyfying initial without state name" do
    expect {
      FiniteMachine.define do
        initial defer: true

        events {
          event :slow, :green  => :yellow
          event :stop, :yellow => :red
        }
      end
    }.to raise_error(FiniteMachine::MissingInitialStateError)
  end

  it "allows to specify inital start event" do
    fsm = FiniteMachine.define do
      initial state: :green, event: :start

      events {
        event :slow, :green  => :none
        event :stop, :yellow => :red
      }
    end

    expect(fsm.current).to eql(:green)
    fsm.slow
    expect(fsm.current).to eql(:none)
    fsm.start
    expect(fsm.current).to eql(:green)
  end

  it "allows to specify deferred inital start event" do
    fsm = FiniteMachine.define do
      initial state: :green, event: :start, defer: true

      events {
        event :slow, :green  => :yellow
        event :stop, :yellow => :red
      }
    end

    expect(fsm.current).to eql(:none)
    fsm.start
    expect(fsm.current).to eql(:green)
  end

  it "evaluates initial state" do
    logger = Logger.new
    fsm = FiniteMachine.define do
      initial logger.level

      events {
        event :slow, :green  => :none
        event :stop, :yellow => :red
      }
    end
    expect(fsm.current).to eql(:pending)
  end
end
