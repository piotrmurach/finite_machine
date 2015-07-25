# encoding: utf-8

require 'spec_helper'

RSpec.describe FiniteMachine::EventsChain, '#transition_from' do
  it "finds transition" do
    transition = spy(:transition, from_state: :green)
    conditions = double(:conditions)
    events_chain = described_class.new

    events_chain.add(:validated, transition)
    expect(events_chain[:validated]).to eq([transition])

    events_chain.transition_from(:validated, :green, conditions)
    expect(transition).to have_received(:check_conditions)
  end
end
