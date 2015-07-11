# encoding: utf-8

require 'spec_helper'

RSpec.describe FiniteMachine::HookEvent, '#new' do
  it "allows to read event name" do
    transition = double(:transition)
    hook_event = described_class.new(:green, transition)
    expect(hook_event.name).to eql(:green)
  end

  it "allows to read event type" do
    transition = double(:transition)
    hook_event = described_class.new(:green, transition)
    expect(hook_event.type).to eql(FiniteMachine::HookEvent)
  end

  it "freezes object" do
    transition = double(:transition)
    hook_event = described_class.new(:green, transition)
    expect { hook_event.name = :red }.to raise_error(RuntimeError)
  end
end
