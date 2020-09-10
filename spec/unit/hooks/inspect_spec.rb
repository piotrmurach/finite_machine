# frozen_string_literal: true

RSpec.describe FiniteMachine::Hooks, "#inspect" do
  it "displays name and transitions" do
    hooks = FiniteMachine::Hooks.new
    hook = -> { }
    event = FiniteMachine::HookEvent::Enter
    hooks_map = {event => {yellow: [hook]}}

    hooks.register(event, :yellow, hook)

    expect(hooks.inspect).to eql("<#FiniteMachine::Hooks:0x#{hooks.object_id.to_s(16)} @hooks_map=#{hooks_map}>")
  end

  it "displays hooks content" do
    hooks = FiniteMachine::Hooks.new
    hook = -> { }
    event = FiniteMachine::HookEvent::Enter
    hooks_map = {event => {yellow: [hook]}}

    hooks.register(event, :yellow, hook)

    expect(hooks.to_s).to eql(hooks_map.to_s)
  end
end
