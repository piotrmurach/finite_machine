# encoding: utf-8

require 'spec_helper'

describe FiniteMachine::Subscribers do
  let(:machine)  { double }
  let(:event)    { double }
  let(:listener) { double }

  subject(:subscribers) { described_class.new(machine) }

  before { subscribers.subscribe(listener) }

  it "checks if any subscribers exist" do
    expect(subscribers.empty?).to be_false
  end

  it "returns index for the subscriber" do
    expect(subscribers.index(listener)).to eql(0)
  end

  it "visits all subscribed listeners for the event" do
    expect(event).to receive(:notify).with(listener)
    subscribers.visit(event)
  end

  it "resets the subscribers" do
    subscribers.reset
    expect(subscribers.empty?).to be_true
  end
end
