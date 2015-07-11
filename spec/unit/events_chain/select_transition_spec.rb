# encoding: utf-8

require 'spec_helper'

RSpec.describe FiniteMachine::EventsChain, '#select_transition' do
  it "selects transition" do
    event = spy(:event)
    conditions = double(:conditions)
    events_chain = described_class.new

    events_chain.add(:validated, event)
    expect(events_chain[:validated]).to eq(event)

    events_chain.select_transition(:validated, conditions)
    expect(event).to have_received(:state_transitions)
  end
end
