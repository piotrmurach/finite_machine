# frozen_string_literal: true

RSpec.describe FiniteMachine::HookEvent, "#build" do
  it "builds action event" do
    hook_event = FiniteMachine::HookEvent::Before.build(:green, :go, :red)
    expect(hook_event.name).to eq(:go)
  end

  it "builds state event" do
    hook_event = FiniteMachine::HookEvent::Enter.build(:green, :go, :red)
    expect(hook_event.name).to eq(:green)
  end
end
