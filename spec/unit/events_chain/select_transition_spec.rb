# encoding: utf-8

require 'spec_helper'

describe FiniteMachine::EventsChain, '#select_transition' do
  let(:object)  { described_class }

  let(:machine) { double(:machine) }

  let(:transition) { double(:transition) }

  subject(:chain) { object.new(machine) }

  it "selects transition" do
    event = double(:event)
    args = double(:args)
    chain.add(:validated, event)
    expect(chain[:validated]).to eq(event)

    expect(event).to receive(:find_transition).with(args)
    chain.select_transition(:validated, args)
  end
end
