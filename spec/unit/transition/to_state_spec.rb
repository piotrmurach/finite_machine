# frozen_string_literal: true

RSpec.describe FiniteMachine::Transition, '#to_state' do
  let(:machine) { double(:machine) }

  it "finds to state" do
    states = {:green => :red}
    transition = described_class.new(machine, :event_name, states: states)

    expect(transition.to_state(:green)).to eq(:red)
  end

  it "finds to state for transition from any state" do
    states = {FiniteMachine::ANY_STATE => :red}
    transition = described_class.new(machine, :event_name, states: states)

    expect(transition.to_state(:green)).to eq(:red)
  end
end
