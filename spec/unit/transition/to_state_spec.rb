# encoding: utf-8

require 'spec_helper'

RSpec.describe FiniteMachine::Transition, '.to_state' do
  let(:machine) { double(:machine) }

  it "finds to state" do
    states = {:green => :red}
    transition = described_class.new(machine, states: states)

    expect(transition.to_state(:green)).to eq(:red)
  end

  it "finds to state for transition from any state" do
    states = {:any => :red}
    transition = described_class.new(machine, states: states)

    expect(transition.to_state(:green)).to eq(:red)
  end

  it "returns from state for cancelled transition" do
    transition = described_class.new(machine, cancelled: true)

    expect(transition.to_state(:green)).to eq(:green)
  end
end
