# encoding: utf-8

require 'spec_helper'

RSpec.describe FiniteMachine::HookEvent, '#new' do
  it "reads event name" do
    hook_event = described_class.new(:green, :go, :green)
    expect(hook_event.name).to eql(:green)
  end

  it "reads event type" do
    hook_event = described_class.new(:green, :go, :green)
    expect(hook_event.type).to eql(FiniteMachine::HookEvent)
  end

  it "reads the from state" do
    hook_event = described_class.new(:green, :go, :red)
    expect(hook_event.from).to eql(:red)
  end

  it "freezes object" do
    hook_event = described_class.new(:green, :go, :green)
    expect { hook_event.name = :red }.to raise_error(RuntimeError)
  end
end
