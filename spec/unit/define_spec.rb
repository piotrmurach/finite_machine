# frozen_string_literal: true

RSpec.describe FiniteMachine, '.define' do
  context 'with block' do
    it "creates system state machine" do
      stub_const("TrafficLights", FiniteMachine.define do
        initial :green

        event :slow,  :green  => :yellow
        event :stop,  :yellow => :red
        event :ready, :red    => :yellow
        event :go,    :yellow => :green
      end)

      lights_fsm_a = TrafficLights.new
      lights_fsm_b = TrafficLights.new

      expect(lights_fsm_a.current).to eql(:green)
      expect(lights_fsm_b.current).to eql(:green)

      lights_fsm_a.slow
      expect(lights_fsm_a.current).to eql(:yellow)
      expect(lights_fsm_b.current).to eql(:green)

      lights_fsm_a.stop
      expect(lights_fsm_a.current).to eql(:red)
      expect(lights_fsm_b.current).to eql(:green)
    end
  end

  context 'without block' do
    it "creates state machine" do
      called = []
      stub_const("TrafficLights", FiniteMachine.define)
      TrafficLights.initial(:green)
      TrafficLights.event(:slow, :green => :yellow)
      TrafficLights.event(:stop, :yellow => :red)
      TrafficLights.event(:ready,:red    => :yellow)
      TrafficLights.event(:go,   :yellow => :green)
      TrafficLights.on_enter(:yellow) { |event| called << 'on_enter_yellow' }
      TrafficLights.handle(FiniteMachine::InvalidStateError) { |exception|
        called << 'error_handler'
      }

      fsm = TrafficLights.new

      expect(fsm.current).to eql(:green)
      fsm.slow
      expect(fsm.current).to eql(:yellow)
      fsm.ready
      expect(fsm.current).to eql(:yellow)
      expect(called).to match_array(['on_enter_yellow', 'error_handler'])
    end
  end
end
