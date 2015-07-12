# encoding: utf-8

require 'spec_helper'

RSpec.describe FiniteMachine::EventsChain, '#find_transition' do
  it "finds transition" do
    transition = spy(:transition)
    conditions = double(:conditions)
    events_chain = described_class.new

    events_chain.add(:validated, transition)
    expect(events_chain[:validated]).to eq([transition])

    events_chain.find_transition(:validated, conditions)
    expect(transition).to have_received(:check_conditions)
  end
end
