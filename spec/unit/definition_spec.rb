# frozen_string_literal: true

RSpec.describe FiniteMachine::Definition do
  before do
    stub_const("Engine", Class.new(described_class) do
      initial :neutral

      event :forward, %i[reverse neutral] => :one
      event :shift, :one => :two
      event :shift, :two => :one
      event :back,  %i[neutral one] => :reverse

      on_enter :reverse do
        target.turn_reverse_lights_on
      end

      on_exit :reverse do
        target.turn_reverse_lights_off
      end

      handle FiniteMachine::InvalidStateError do
        target.turn_reverse_lights_off
      end
    end)
  end

  it "creates unique instances" do
    engine_a = Engine.new
    engine_b = Engine.new
    expect(engine_a).not_to be(engine_b)

    expect(engine_a.current).to eq(:neutral)

    engine_a.forward
    expect(engine_a.current).to eq(:one)
    expect(engine_b.current).to eq(:neutral)
  end

  it "creates a standalone machine" do
    stub_const("Car", Class.new do
      def turn_reverse_lights_off
        @reverse_lights = false
      end

      def turn_reverse_lights_on
        @reverse_lights = true
      end

      def reverse_lights?
        @reverse_lights ||= false
      end
    end)

    car = Car.new
    engine = Engine.new(car)
    expect(engine.current).to eq(:neutral)

    engine.forward
    expect(engine.current).to eq(:one)
    expect(car.reverse_lights?).to eq(false)

    engine.back
    expect(engine.current).to eq(:reverse)
    expect(car.reverse_lights?).to eq(true)

    engine.shift
    expect(engine.current).to eq(:reverse)
    expect(car.reverse_lights?).to eq(false)
  end

  it "uses any_state method inside the definition class" do
    stub_const("TrafficLights", Class.new(described_class) do
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

  it "uses any_event method inside the definition class" do
    stub_const("TrafficLights", Class.new(described_class) do
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

  it "supports definitions inheritance" do
    stub_const("GenericStateMachine", Class.new(described_class) do
      initial :red

      event :start, :red => :green

      on_enter { target << "generic" }
    end)

    stub_const("SpecificStateMachine", Class.new(GenericStateMachine) do
      event :stop, :green => :yellow

      on_enter(:yellow) { target << "specific" }
    end)

    called = []
    generic_fsm  = GenericStateMachine.new(called)
    specific_fsm = SpecificStateMachine.new(called)

    expect(generic_fsm.states).to match_array(%i[none red green])
    expect(specific_fsm.states).to match_array(%i[none red green yellow])

    expect(specific_fsm.current).to eq(:red)

    specific_fsm.start
    expect(specific_fsm.current).to eq(:green)
    expect(called).to eq(%w[generic])

    specific_fsm.stop
    expect(specific_fsm.current).to eq(:yellow)
    expect(called).to eq(%w[generic generic specific])
  end
end
