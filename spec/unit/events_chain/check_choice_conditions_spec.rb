# encoding: utf-8

require 'spec_helper'

RSpec.describe FiniteMachine::EventsChain, '#clear' do
  it "clears chain events" do
    event = double(:event)
    events_chain = described_class.new
    events_chain.add(:validated, event)
    expect(events_chain.empty?).to be(false)

    events_chain.clear
    expect(events_chain.empty?).to be(true)
  end
end
