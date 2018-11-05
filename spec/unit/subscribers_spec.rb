# frozen_string_literal: true

RSpec.describe FiniteMachine::Subscribers do
  let(:listener) { double }

  it "checks if any subscribers exist" do
    subscribers = described_class.new
    expect(subscribers.empty?).to eq(true)
    subscribers.subscribe(listener)
    expect(subscribers.empty?).to eq(false)
  end

  it "allows to subscribe multiple listeners" do
    subscribers = described_class.new
    subscribers.subscribe(listener, listener)
    expect(subscribers.size).to eq(2)
  end

  it "returns index for the subscriber" do
    subscribers = described_class.new
    subscribers.subscribe(listener)
    expect(subscribers.index(listener)).to eql(0)
  end

  it "visits all subscribed listeners for the event" do
    subscribers = described_class.new
    subscribers.subscribe(listener)
    event = spy(:event)
    subscribers.visit(event)
    expect(event).to have_received(:notify).with(listener)
  end

  it "resets the subscribers" do
    subscribers = described_class.new
    subscribers.subscribe(listener)
    expect(subscribers.empty?).to eq(false)
    subscribers.reset
    expect(subscribers.empty?).to eq(true)
  end
end
