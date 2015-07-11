# encoding: utf-8

require 'spec_helper'

RSpec.describe FiniteMachine::EventsChain, '#insert' do
  it "inspects empty events chain" do
    events_chain = described_class.new
    expect(events_chain.inspect).to eq("<#FiniteMachine::EventsChain @chain={}>")
  end

  it "inspect events chain" do
    event = double(:event)
    events_chain = described_class.new
    events_chain.add(:validated, event)
    expect(events_chain.inspect).to eq("<#FiniteMachine::EventsChain @chain=#{{validated: event}}>")
  end

  it "prints events chain" do
    event = double(:event)
    events_chain = described_class.new
    events_chain.add(:validated, event)
    expect(events_chain.to_s).to eq("#{{validated: event}}")
  end
end
