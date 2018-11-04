# frozen_string_literal: true

RSpec.describe FiniteMachine::HookEvent, '#any_state_or_event' do
  it "infers default name for state" do
    hook_event = described_class::Enter
    expect(described_class.any_state_or_event(hook_event)).to eq(FiniteMachine::ANY_STATE)
  end

  it "infers default name for event" do
    hook_event = described_class::Before
    expect(described_class.any_state_or_event(hook_event)).to eq(FiniteMachine::ANY_EVENT)
  end
end
