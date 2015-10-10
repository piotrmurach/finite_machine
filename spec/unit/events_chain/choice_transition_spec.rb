# encoding: utf-8

require 'spec_helper'

RSpec.describe FiniteMachine::EventsChain, '.choice_transition?' do

  it "checks if transition has many branches" do
    transition_a = double(:transition_a, matches?: true)
    transition_b = double(:transition_b, matches?: true)

    events_chain = described_class.new
    events_chain.add(:go, transition_a)
    events_chain.add(:go, transition_b)

    expect(events_chain.choice_transition?(:go, :green)).to eq(true)
  end

  it "checks that transition has no branches" do
    transition_a = double(:transition_a, matches?: false)
    transition_b = double(:transition_b, matches?: true)

    events_chain = described_class.new
    events_chain.add(:go, transition_a)
    events_chain.add(:go, transition_b)

    expect(events_chain.choice_transition?(:go, :green)).to eq(false)
  end
end
