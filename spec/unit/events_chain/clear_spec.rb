# encoding: utf-8

require 'spec_helper'

describe FiniteMachine::EventsChain, '#insert' do
  let(:object)  { described_class }

  let(:machine) { double(:machine) }

  let(:transition) { double(:transition) }

  subject(:chain) { object.new(machine) }

  it "inserts transition" do
    event = double(:event)
    chain.add(:validated, event)
    expect(chain[:validated]).to eq(event)

    expect(event).to receive(:<<).with(transition)
    chain.insert(:validated, transition)
  end

  it "fails to insert transition" do
    expect(chain.insert(:validated, transition)).to be(false)
  end
end
