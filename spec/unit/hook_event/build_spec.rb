# encoding: utf-8

require 'spec_helper'

RSpec.describe FiniteMachine::HookEvent, '#build' do
  it "builds action event" do
    transition = double(:transition, name: :go)
    hook_event = FiniteMachine::HookEvent::Before.build(:green, transition)
    expect(hook_event.name).to eq(:go)
  end

  it "builds state event" do
    transition = double(:transition, name: :go)
    hook_event = FiniteMachine::HookEvent::Enter.build(:green, transition)
    expect(hook_event.name).to eq(:green)
  end
end
