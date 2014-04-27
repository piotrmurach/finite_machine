# encoding: utf-8

require 'spec_helper'

describe FiniteMachine, 'define' do

  context 'with block' do
    it "creates system state machine" do
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

      fsm.slow
      expect(fsm.current).to eql(:yellow)
      fsm.stop
      expect(fsm.current).to eql(:red)
      fsm.ready
      expect(fsm.current).to eql(:yellow)
      fsm.go
      expect(fsm.current).to eql(:green)
    end
  end

  context 'without block' do
    it "creates state machine" do
      called = []
      fsm = FiniteMachine.define
      fsm.initial(:green)
      fsm.event(:slow, :green => :yellow)
      fsm.event(:stop, :yellow => :red)
      fsm.event(:ready,:red    => :yellow)
      fsm.event(:go,   :yellow => :green)
      fsm.on_enter(:yellow) { |event| called << 'on_enter_yellow' }
      fsm.handle(FiniteMachine::InvalidStateError) { |exception|
        called << 'error_handler'
      }

      expect(fsm.current).to eql(:green)
      fsm.slow
      fsm.ready
      expect(called).to match_array(['on_enter_yellow', 'error_handler'])
    end
  end

  xit "creates multiple machines"
end
