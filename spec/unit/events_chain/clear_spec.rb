# encoding: utf-8

require 'spec_helper'

RSpec.describe FiniteMachine::EventsChain, '#insert' do
  it "adds transitions" do
    transition = double(:transition)
    events_chain = described_class.new

    events_chain.add(:validated, transition)
    expect(events_chain[:validated]).to eq([transition])

    events_chain.add(:validated, transition)
    expect(events_chain[:validated]).to eq([transition, transition])
  end
end
