# encoding: utf-8

require 'spec_helper'

RSpec.describe FiniteMachine::EventsChain, '#insert' do
  it "inserts transition" do
    transition = double(:transition)
    events_chain = described_class.new

    events_chain.add(:validated, transition)
    expect(events_chain[:validated]).to eq([transition])

    events_chain.insert(:validated, transition)
    expect(events_chain[:validated]).to eq([transition, transition])
  end

  it "fails to insert transition" do
    transition = double(:transition)
    events_chain = described_class.new

    expect(events_chain.insert(:validated, transition)).to be(false)
  end
end
