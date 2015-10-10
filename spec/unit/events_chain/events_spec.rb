# encoding: utf-8

require 'spec_helper'

RSpec.describe FiniteMachine::EventsChain, '.events' do
  it "has no event names" do
    events_chain = described_class.new
    expect(events_chain.events).to eq([])
  end

  it "returns all event names" do
    events_chain = described_class.new
    transition = double(:transition)
    events_chain.add(:ready, transition)
    events_chain.add(:go, transition)
    expect(events_chain.events).to match_array([:ready, :go])
  end
end
