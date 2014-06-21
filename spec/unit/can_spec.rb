# encoding: utf-8

require 'spec_helper'

describe FiniteMachine, 'can?' do
  before(:each) {
    Bug = Class.new do
      def pending?
        false
      end
    end
  }

  it "allows to check if event can be fired" do
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

    expect(fsm.can?(:slow)).to be_true
    expect(fsm.cannot?(:stop)).to be_true
    expect(fsm.can?(:ready)).to be_false
    expect(fsm.can?(:go)).to be_false

    fsm.slow
    expect(fsm.current).to eql(:yellow)

    expect(fsm.can?(:slow)).to be_false
    expect(fsm.can?(:stop)).to be_true
    expect(fsm.can?(:ready)).to be_false
    expect(fsm.can?(:go)).to be_true

    fsm.stop
    expect(fsm.current).to eql(:red)

    expect(fsm.can?(:slow)).to be_false
    expect(fsm.can?(:stop)).to be_false
    expect(fsm.can?(:ready)).to be_true
    expect(fsm.can?(:go)).to be_false

    fsm.ready
    expect(fsm.current).to eql(:yellow)

    expect(fsm.can?(:slow)).to be_false
    expect(fsm.can?(:stop)).to be_true
    expect(fsm.can?(:ready)).to be_false
    expect(fsm.can?(:go)).to be_true
  end

  context 'with conditionl transition' do
    it "evalutes condition with parameters" do
      fsm = FiniteMachine.define do
        initial :green

        events {
          event :slow,  :green  => :yellow
          event :stop,  :yellow => :red, if: proc { |_, state| state }
        }
      end
      expect(fsm.current).to eq(:green)
      expect(fsm.can?(:slow)).to be_true
      expect(fsm.can?(:stop)).to be_false

      fsm.slow
      expect(fsm.current).to eq(:yellow)
      expect(fsm.can?(:stop, false)).to be_false
      expect(fsm.can?(:stop, true)).to be_true
    end

    it "checks against target and grouped events" do
      bug = Bug.new
      fsm = FiniteMachine.define do
        initial :initial

        target bug

        events {
          event :bump, :initial => :low
          event :bump, :low     => :medium, if: :pending?
          event :bump, :medium  => :high
        }
      end
      expect(fsm.current).to eq(:initial)

      expect(fsm.can?(:bump)).to be_true
      fsm.bump
      expect(fsm.can?(:bump)).to be_false
    end
  end
end
