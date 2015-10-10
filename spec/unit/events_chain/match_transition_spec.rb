# encoding: utf-8

require 'spec_helper'

RSpec.describe FiniteMachine::EventsChain, '.match_transition' do
  it "matches transition with conditions from a given state" do
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
end
