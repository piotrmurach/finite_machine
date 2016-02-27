# encoding: utf-8

require 'spec_helper'

RSpec.describe FiniteMachine::EventQueue do

  subject(:event_queue) { described_class.new }

  it "dispatches all events" do
    event_queue.start
    called = []
    event1 = double(:event1, dispatch: called << 'event1_dispatched')
    event2 = double(:event2, dispatch: called << 'event2_dispatched')
    expect(event_queue.size).to be_zero
    event_queue << event1
    event_queue << event2
    event_queue.join(0.001)
    expect(called).to match_array(['event1_dispatched', 'event2_dispatched'])
  end

  it "logs error" do
    event_queue.start
    event = spy(:event)
    allow(event).to receive(:dispatch) { raise }
    expect(FiniteMachine::Logger).to receive(:error)
    event_queue << event
    event_queue.join(0.01)
    expect(event_queue).to be_empty
  end

  it "notifies listeners" do
    event_queue.start
    called = []
    event1 = double(:event1, dispatch: true)
    event2 = double(:event2, dispatch: true)
    event3 = double(:event3, dispatch: true)
    event_queue.subscribe(:listener1) { |event| called << event }
    event_queue << event1 << event2 << event3
    event_queue.join(0.02)
    event_queue.shutdown
    expect(called).to match_array([event1, event2, event3])
  end

  it "allows to shutdown event queue" do
    event_queue.start
    event1 = double(:event1, dispatch: true)
    event2 = double(:event2, dispatch: true)
    event3 = double(:event3, dispatch: true)
    expect(event_queue.alive?).to be(true)
    event_queue << event1
    event_queue << event2
    event_queue.shutdown
    event_queue << event3
    event_queue.join(0.001)
    expect(event_queue.alive?).to be(false)
  end
end
