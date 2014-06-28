# encoding: utf-8

require 'spec_helper'

describe FiniteMachine::EventsChain, '#insert' do
  let(:object)  { described_class }

  let(:machine) { double(:machine) }

  subject(:chain) { object.new(machine) }

  it "inspects empty chain" do
    expect(chain.inspect).to eq("<#FiniteMachine::EventsChain @chain={}>")
  end

  it "inspect chain" do
    event = double(:event)
    chain.add(:validated, event)
    expect(chain.inspect).to eq("<#FiniteMachine::EventsChain @chain=#{{validated: event}}>")
  end

  it "prints chain" do
    event = double(:event)
    chain.add(:validated, event)
    expect(chain.to_s).to eq("#{{validated: event}}")
  end
end
