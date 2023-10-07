# frozen_string_literal: true

RSpec.describe FiniteMachine, ".new" do
  context "with block" do
    it "creates a state machine" do
      fsm = described_class.new(called = []) do
        initial :green

        event :slow,  :green  => :yellow
        event :stop,  :yellow => :red
        event :ready, :red    => :yellow
        event :go,    :yellow => :green

        on_enter(:yellow) { target << "on_enter_yellow" }

        handle(FiniteMachine::InvalidStateError) { target << "error_handler" }
      end

      expect(fsm.current).to eq(:green)
      fsm.slow
      expect(fsm.current).to eq(:yellow)
      fsm.stop
      expect(fsm.current).to eq(:red)
      fsm.ready
      expect(fsm.current).to eq(:yellow)
      fsm.go
      expect(fsm.current).to eq(:green)
      fsm.stop
      expect(called).to eq(%w[on_enter_yellow on_enter_yellow error_handler])
    end

    it "uses any_state method inside the new method block" do
      fsm = described_class.new(called = []) do
        initial :green

        event :slow, any_state => :yellow

        on_enter(any_state) { |event| target << "enter_#{event.to}" }
        on_transition(any_state) { |event| target << "transition_#{event.to}" }
        on_exit(any_state) { |event| target << "exit_#{event.from}" }
      end

      fsm.slow

      expect(fsm.current).to eq(:yellow)
      expect(called).to eq(%w[exit_green transition_yellow enter_yellow])
    end

    it "uses any_event method inside the new method block" do
      fsm = described_class.new(called = []) do
        initial :green

        event :slow, :green => :yellow

        on_before(any_event) { |event| target << "before_#{event.name}" }
        on_after(any_event) { |event| target << "after_#{event.name}" }
      end

      fsm.slow

      expect(fsm.current).to eq(:yellow)
      expect(called).to eq(%w[before_slow after_slow])
    end
  end

  context "without block" do
    it "creates a state machine" do
      fsm = described_class.new(called = [])
      fsm.initial(:green)
      fsm.event(:slow,  :green => :yellow)
      fsm.event(:stop,  :yellow => :red)
      fsm.event(:ready, :red    => :yellow)
      fsm.event(:go,    :yellow => :green)
      fsm.on_enter(:yellow) { target << "on_enter_yellow" }
      fsm.handle(FiniteMachine::InvalidStateError) { target << "error_handler" }

      fsm.init
      expect(fsm.current).to eq(:green)
      fsm.slow
      expect(fsm.current).to eq(:yellow)
      fsm.stop
      expect(fsm.current).to eq(:red)
      fsm.ready
      expect(fsm.current).to eq(:yellow)
      fsm.go
      expect(fsm.current).to eq(:green)
      fsm.stop
      expect(called).to eq(%w[on_enter_yellow on_enter_yellow error_handler])
    end

    it "uses any_state method outside the new method block" do
      fsm = described_class.new(called = [])
      fsm.initial(:green)
      fsm.event(:slow, fsm.any_state => :yellow)
      fsm.on_enter(fsm.any_state) do |event|
        target << "enter_#{event.to}"
      end
      fsm.on_transition(fsm.any_state) do |event|
        target << "transition_#{event.to}"
      end
      fsm.on_exit(fsm.any_state) do |event|
        target << "exit_#{event.from}"
      end

      fsm.init
      fsm.slow

      expect(fsm.current).to eq(:yellow)
      expect(called).to eq(%w[exit_green transition_yellow enter_yellow])
    end

    it "uses any_event method outside the new method block" do
      fsm = described_class.new(called = [])
      fsm.initial(:green)
      fsm.event(:slow, :green => :yellow)
      fsm.on_before(fsm.any_event) do |event|
        target << "before_#{event.name}"
      end
      fsm.on_after(fsm.any_event) do |event|
        target << "after_#{event.name}"
      end

      fsm.init
      fsm.slow

      expect(fsm.current).to eq(:yellow)
      expect(called).to eq(%w[before_slow after_slow])
    end
  end
end
