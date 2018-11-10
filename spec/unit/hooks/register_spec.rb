# frozen_string_literal: true

RSpec.describe FiniteMachine::Hooks, '#register' do
  it "adds and removes a single hook" do
    hooks = FiniteMachine::Hooks.new
    expect(hooks).to be_empty

    event_type = FiniteMachine::HookEvent::Before
    hook = -> { }

    hooks.register(event_type, :foo, hook)
    expect(hooks[event_type][:foo]).to eq([hook])

    hooks.unregister(event_type, :foo, hook)
    expect(hooks[event_type][:foo]).to eq([])
  end
end
