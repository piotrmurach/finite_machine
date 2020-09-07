# frozen_string_literal: true

RSpec.describe FiniteMachine::Definition, "#alias_target" do

  before do
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
  end

  it "aliases target" do
    car = Car.new
    fsm = FiniteMachine.new(car, alias_target: :delorean)

    expect(fsm.target).to eq(car)
    expect { fsm.car }.to raise_error(NoMethodError)
    expect(fsm.delorean).to eq(car)
  end

  it "scopes the target alias to a state machine instance" do
    delorean = Car.new
    batmobile = Car.new
    fsm_a = FiniteMachine.new(delorean, alias_target: :delorean)
    fsm_b = FiniteMachine.new(batmobile, alias_target: :batmobile)

    expect(fsm_a.delorean).to eq(delorean)
    expect { fsm_a.batmobile }.to raise_error(NameError)

    expect(fsm_b.batmobile).to eq(batmobile)
    expect { fsm_b.delorean }.to raise_error(NameError)
  end

  context "when outside definition" do
    before do
      stub_const("Engine", Class.new(FiniteMachine::Definition) do
        initial :neutral

        event :forward, [:reverse, :neutral] => :one
        event :shift, :one => :two
        event :shift, :two => :one
        event :back,  [:neutral, :one] => :reverse

        on_enter :reverse do |event|
          car.turn_reverse_lights_on
        end

        on_exit :reverse do |event|
          car.turn_reverse_lights_off
        end

        handle FiniteMachine::InvalidStateError do |exception| end
      end)
    end

    it "creates unique instances" do
      engine_a = Engine.new(alias_target: :car)
      engine_b = Engine.new(alias_target: :car)
      expect(engine_a).not_to be(engine_b)

      engine_a.forward
      expect(engine_a.current).to eq(:one)
      expect(engine_b.current).to eq(:neutral)
    end

    it "allows to create standalone machine" do
      car = Car.new
      engine = Engine.new(car, alias_target: :car)
      expect(engine.current).to eq(:neutral)

      engine.forward
      expect(engine.current).to eq(:one)
      expect(car.reverse_lights?).to be false

      engine.back
      expect(engine.current).to eq(:reverse)
      expect(car.reverse_lights?).to be true
    end
  end

  context "when target aliased inside definition" do
    before do
      stub_const("Matter", Class.new do
        attr_accessor :state

        def initialize
          @state = :gas
        end
      end)

      stub_const("Diesel", Class.new(FiniteMachine::Definition) do
        alias_target :matter

        initial :gas

        event :fuel, :gas => :liquid

        on_transition do |event|
          matter.state = event.to
        end
      end)
    end

    it "uses alias_target helper" do
      matter = Matter.new
      diesel = Diesel.new(matter)
      expect(diesel.current).to eq(:gas)
      expect(matter.state).to eq(:gas)

      diesel.fuel

      expect(diesel.current).to eq(:liquid)
      expect(matter.state).to eq(:liquid)
    end

    it "adds additional alias with alias_target helper" do
      matter = Matter.new
      diesel = Diesel.new(matter)
      expect(diesel.env.aliases).to eq(%i[matter])

      diesel.alias_target :substance

      expect(diesel.env.aliases).to eq(%i[matter substance])
    end
  end
end
