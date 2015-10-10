# encoding: utf-8

require 'spec_helper'

RSpec.describe FiniteMachine::EventsChain, '.cancel_transitions' do
  it "sets cancel status for chosen transitions" do
    events_chain = described_class.new
    transition_a = spy(:transition_a, cancelled: false)
    transition_b = spy(:transition_b, cancelled: false)
    transition_c = spy(:transition_c, cancelled: false)

    events_chain.add(:start, transition_a)
    events_chain.add(:start, transition_b)
    events_chain.add(:finish, transition_c)

    events_chain.cancel_transitions(:start, true)

    expect(transition_a).to have_received(:cancelled=).with(true)
    expect(transition_b).to have_received(:cancelled=).with(true)
    expect(transition_c).not_to have_received(:cancelled=)
  end
end
