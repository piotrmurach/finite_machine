# frozen_string_literal: true

RSpec.describe FiniteMachine::Definition, 'definition' do

  before do
    class Engine < FiniteMachine::Definition
      initial :neutral

      event :forward, [:reverse, :neutral] => :one
      event :shift, :one => :two
      event :shift, :two => :one
      event :back,  [:neutral, :one] => :reverse

      callbacks {
        on_enter :reverse do |event|
          target.turn_reverse_lights_on
        end

        on_exit :reverse do |event|
          target.turn_reverse_lights_off
        end
      }

      handlers {
        handle FiniteMachine::InvalidStateError do |exception| end
      }
    end
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

  it "allows to create standalone machine" do
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
  end

  it "supports inheritance of definitions" do
    class GenericStateMachine < FiniteMachine::Definition
      initial :red

      event :start, :red => :green

      callbacks {
        on_enter { |event| target << 'generic' }
      }
    end

    class SpecificStateMachine < GenericStateMachine
      event :stop, :green => :yellow

      callbacks {
        on_enter(:yellow) { |event| target << 'specific' }
      }
    end

    called = []
    generic_fsm  = GenericStateMachine.new(called)
    specific_fsm = SpecificStateMachine.new(called)

    expect(generic_fsm.states).to match_array([:none, :red, :green])
    expect(specific_fsm.states).to match_array([:none, :red, :green, :yellow])

    expect(specific_fsm.current).to eq(:red)

    specific_fsm.start
    expect(specific_fsm.current).to eq(:green)
    expect(called).to match_array(['generic'])

    specific_fsm.stop
    expect(specific_fsm.current).to eq(:yellow)
    expect(called).to match_array(['generic', 'generic', 'specific'])
  end
end
