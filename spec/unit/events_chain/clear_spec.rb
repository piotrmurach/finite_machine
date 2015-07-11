# encoding: utf-8

require 'spec_helper'

RSpec.describe FiniteMachine::EventsChain, '#insert' do
  let(:transition) { double(:transition) }

  it "inserts transition" do
    event = double(:event)
    events_chain = described_class.new
    events_chain.add(:validated, event)
    expect(events_chain[:validated]).to eq(event)

    expect(event).to receive(:<<).with(transition)
    events_chain.insert(:validated, transition)
  end

  it "fails to insert transition" do
    events_chain = described_class.new
    expect(events_chain.insert(:validated, transition)).to be(false)
  end
end
