# encoding: utf-8

require 'spec_helper'

RSpec.describe FiniteMachine::EventsChain, '#inspect' do
  it "inspects empty events chain" do
    events_chain = described_class.new
    expect(events_chain.inspect).to eq("<#FiniteMachine::EventsChain @events={}>")
  end

  it "inspect events chain" do
    transition = double(:transition)
    events_chain = described_class.new
    events_chain.add(:validated, transition)
    expect(events_chain.inspect).to eq("<#FiniteMachine::EventsChain @events=#{{validated: [transition]}}>")
  end

  it "prints events chain" do
    transition = double(:transition)
    events_chain = described_class.new
    events_chain.add(:validated, transition)
    expect(events_chain.to_s).to eq("#{{validated: [transition]}}")
  end
end
