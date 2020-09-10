# frozen_string_literal: true

RSpec.describe FiniteMachine::Transition, "#matches?" do
  let(:machine) { double(:machine) }

  it "matches from state" do
    states = {:green => :red}
    transition = described_class.new(machine, :event_name, states: states)

    expect(transition.matches?(:green)).to eq(true)
    expect(transition.matches?(:red)).to eq(false)
  end

  it "matches any state" do
    states = {FiniteMachine::ANY_STATE => :red}
    transition = described_class.new(machine, :event_name, states: states)

    expect(transition.matches?(:green)).to eq(true)
  end
end

