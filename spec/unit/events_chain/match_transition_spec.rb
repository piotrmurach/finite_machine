# encoding: utf-8

require 'spec_helper'

RSpec.describe FiniteMachine::EventsChain, '.match_transition' do
  it "matches transition without conditions" do
    transition_a = double(:transition_a, matches?: false)
    transition_b = double(:transition_b, matches?: true)
    events_chain = described_class.new

    events_chain.add(:a, transition_a)
    events_chain.add(:a, transition_b)

    expect(events_chain.match_transition(:a, :green)).to eq(transition_b)
  end

  it "fails to match any transition" do
    events_chain = described_class.new

    expect(events_chain.match_transition(:a, :green)).to eq(nil)
  end

  it "matches transition with conditions" do
    transition_a = double(:transition_a, matches?: true)
    transition_b = double(:transition_b, matches?: true)
    events_chain = described_class.new

    events_chain.add(:a, transition_a)
    events_chain.add(:a, transition_b)

    allow(transition_a).to receive(:check_conditions).and_return(false)
    allow(transition_b).to receive(:check_conditions).and_return(true)

    expect(events_chain.match_transition_with(:a, :green, 'Piotr')).to eq(transition_b)
    expect(transition_a).to have_received(:check_conditions).with('Piotr')
  end
end
