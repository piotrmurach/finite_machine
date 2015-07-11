# encoding: utf-8

require 'spec_helper'

RSpec.describe FiniteMachine::EventsChain, '#insert' do
  let(:transition) { double(:transition) }

  it "inserts transition" do
    event = double(:event)
    chain = described_class.new
    chain.add(:validated, event)
    expect(chain[:validated]).to eq(event)

    expect(event).to receive(:<<).with(transition)
    chain.insert(:validated, transition)
  end

  it "fails to insert transition" do
    chain = described_class.new
    expect(chain.insert(:validated, transition)).to be false
  end
end
