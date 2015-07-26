require 'spec_helper'

RSpec.describe FiniteMachine::EventsChain do
  it "finds current states for event name" do
    transition = spy(:transition, states: {:red => :yellow, :yellow => :green})
    events_chain = described_class.new
    events_chain.add(:start, transition)

    expect(events_chain.states_for(:start)).to eq([:red, :yellow])
  end

  it "fails to find any states for event name" do
    events_chain = described_class.new

    expect(events_chain.states_for(:start)).to eq([])
  end
end
