# frozen_string_literal: true

RSpec.describe FiniteMachine::Hooks, '#clear' do
  it "clears all registered hooks" do
    hooks = described_class.new

    event_type = FiniteMachine::HookEvent::Before
    hook = -> { }
    hooks.register(event_type, :foo, hook)
    hooks.register(event_type, :bar, hook)

    expect(hooks.empty?).to eq(false)
    hooks.clear
    expect(hooks.empty?).to eq(true)
  end
end
