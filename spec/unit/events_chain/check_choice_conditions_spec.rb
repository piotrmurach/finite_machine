# encoding: utf-8

require 'spec_helper'

RSpec.describe FiniteMachine::EventsChain, '#clear' do
  let(:object)  { described_class }

  let(:machine) { double(:machine) }

  subject(:chain) { object.new(machine) }

  it "clears chain events" do
    event = double(:event)
    chain.add(:validated, event)
    expect(chain.empty?).to be(false)

    chain.clear
    expect(chain.empty?).to be(true)
  end
end
