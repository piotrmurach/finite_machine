# frozen_string_literal: true

RSpec.describe FiniteMachine, ".define" do
  context "with block" do
    it "creates a state machine" do
      stub_const("TrafficLights", described_class.define do
        initial :green

        event :slow,  :green  => :yellow
        event :stop,  :yellow => :red
        event :ready, :red    => :yellow
        event :go,    :yellow => :green
      end)

      fsm_a = TrafficLights.new
      fsm_b = TrafficLights.new

      expect(fsm_a.current).to eq(:green)
      expect(fsm_b.current).to eq(:green)

      fsm_a.slow
      expect(fsm_a.current).to eq(:yellow)
      expect(fsm_b.current).to eq(:green)

      fsm_a.stop
      expect(fsm_a.current).to eq(:red)
      expect(fsm_b.current).to eq(:green)
    end

    it "uses any_state method inside the define method block" do
      stub_const("TrafficLights", described_class.define do
        initial :green

        event :slow, any_state => :yellow

        on_enter(any_state) { |event| target << "enter_#{event.to}" }
        on_transition(any_state) { |event| target << "transition_#{event.to}" }
        on_exit(any_state) { |event| target << "exit_#{event.from}" }
      end)

      fsm = TrafficLights.new(called = [])
      fsm.slow

      expect(fsm.current).to eq(:yellow)
      expect(called).to eq(%w[exit_green transition_yellow enter_yellow])
    end

    it "uses any_event method inside the define method block" do
      stub_const("TrafficLights", described_class.define do
        initial :green

        event :slow, :green => :yellow

        on_before(any_event) { |event| target << "before_#{event.name}" }
        on_after(any_event) { |event| target << "after_#{event.name}" }
      end)

      fsm = TrafficLights.new(called = [])
      fsm.slow

      expect(fsm.current).to eq(:yellow)
      expect(called).to eq(%w[before_slow after_slow])
    end
  end

  context "without block" do
    it "creates a state machine" do
      called = []
      stub_const("TrafficLights", described_class.define)
      TrafficLights.initial(:green)
      TrafficLights.event(:slow,  :green => :yellow)
      TrafficLights.event(:stop,  :yellow => :red)
      TrafficLights.event(:ready, :red    => :yellow)
      TrafficLights.event(:go,    :yellow => :green)
      TrafficLights.on_enter(:yellow) { called << "on_enter_yellow" }
      TrafficLights.handle(FiniteMachine::InvalidStateError) do
        called << "error_handler"
      end

      fsm = TrafficLights.new

      expect(fsm.current).to eq(:green)
      fsm.slow
      expect(fsm.current).to eq(:yellow)
      fsm.ready
      expect(fsm.current).to eq(:yellow)
      expect(called).to eq(%w[on_enter_yellow error_handler])
    end

    it "uses any_state method outside the define method block" do
      stub_const("TrafficLights", described_class.define)
      TrafficLights.initial(:green)
      TrafficLights.event(:slow, TrafficLights.any_state => :yellow)
      TrafficLights.on_enter(TrafficLights.any_state) do |event|
        target << "enter_#{event.to}"
      end
      TrafficLights.on_transition(TrafficLights.any_state) do |event|
        target << "transition_#{event.to}"
      end
      TrafficLights.on_exit(TrafficLights.any_state) do |event|
        target << "exit_#{event.from}"
      end

      fsm = TrafficLights.new(called = [])
      fsm.slow

      expect(fsm.current).to eq(:yellow)
      expect(called).to eq(%w[exit_green transition_yellow enter_yellow])
    end

    it "uses any_event method outside the define method block" do
      stub_const("TrafficLights", described_class.define)
      TrafficLights.initial(:green)
      TrafficLights.event(:slow, :green => :yellow)
      TrafficLights.on_before(TrafficLights.any_event) do |event|
        target << "before_#{event.name}"
      end
      TrafficLights.on_after(TrafficLights.any_event) do |event|
        target << "after_#{event.name}"
      end

      fsm = TrafficLights.new(called = [])
      fsm.slow

      expect(fsm.current).to eq(:yellow)
      expect(called).to eq(%w[before_slow after_slow])
    end
  end
end
