# encoding: utf-8

RSpec.describe FiniteMachine::HookEvent, '#infer_default_name' do
  it "infers default name for state" do
    hook_event = described_class::Enter
    expect(described_class.infer_default_name(hook_event)).to eq(FiniteMachine::ANY_STATE)
  end

  it "infers default name for event" do
    hook_event = described_class::Before
    expect(described_class.infer_default_name(hook_event)).to eq(FiniteMachine::ANY_EVENT)
  end
end
