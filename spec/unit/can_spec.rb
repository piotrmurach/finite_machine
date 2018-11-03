# frozen_string_literal: true

RSpec.describe FiniteMachine, 'can?' do
  before(:each) {
    stub_const("Bug", Class.new do
      def pending?
        false
      end
    end)
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

    expect(fsm.can?(:slow)).to be(true)
    expect(fsm.cannot?(:stop)).to be(true)
    expect(fsm.can?(:ready)).to be(false)
    expect(fsm.can?(:go)).to be(false)

    fsm.slow
    expect(fsm.current).to eql(:yellow)

    expect(fsm.can?(:slow)).to be(false)
    expect(fsm.can?(:stop)).to be(true)
    expect(fsm.can?(:ready)).to be(false)
    expect(fsm.can?(:go)).to be(true)

    fsm.stop
    expect(fsm.current).to eql(:red)

    expect(fsm.can?(:slow)).to be(false)
    expect(fsm.can?(:stop)).to be(false)
    expect(fsm.can?(:ready)).to be(true)
    expect(fsm.can?(:go)).to be(false)

    fsm.ready
    expect(fsm.current).to eql(:yellow)

    expect(fsm.can?(:slow)).to be(false)
    expect(fsm.can?(:stop)).to be(true)
    expect(fsm.can?(:ready)).to be(false)
    expect(fsm.can?(:go)).to be(true)
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
      expect(fsm.can?(:slow)).to be(true)
      expect(fsm.can?(:stop)).to be(false)

      fsm.slow
      expect(fsm.current).to eq(:yellow)
      expect(fsm.can?(:stop, false)).to be(false)
      expect(fsm.can?(:stop, true)).to be(true)
    end

    it "checks against target and grouped events" do
      bug = Bug.new
      fsm = FiniteMachine.define(target: bug) do
        initial :initial

        events {
          event :bump, :initial => :low
          event :bump, :low     => :medium, if: :pending?
          event :bump, :medium  => :high
        }
      end
      expect(fsm.current).to eq(:initial)

      expect(fsm.can?(:bump)).to be(true)
      fsm.bump
      expect(fsm.can?(:bump)).to be(false)
    end
  end
end
