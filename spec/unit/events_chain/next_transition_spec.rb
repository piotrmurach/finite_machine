# encoding: utf-8

require 'spec_helper'

RSpec.describe FiniteMachine::EventsChain, '.next_transition' do
  let(:machine) { spy(:machine) }

  it "finds matching transition by name" do
    transition_a = double(:transition_a, current?: false)
    transition_b = double(:transition_b, current?: true)
    event = FiniteMachine::Event.new(:go, machine)
    event << transition_a
    event << transition_b

    events_chain = described_class.new(machine)
    events_chain.add(:go, event)

    expect(events_chain.next_transition(:go)).to eq(transition_b)
  end

  it "choses first available transition" do
    transition_a = double(:transition_a, current?: false)
    transition_b = double(:transition_b, current?: false)
    event = FiniteMachine::Event.new(:go, machine)
    event << transition_a
    event << transition_b

    events_chain = described_class.new(machine)
    events_chain.add(:go, event)

    expect(events_chain.next_transition(:go)).to eq(transition_a)
  end
end
