# frozen_string_literal: true

RSpec.describe FiniteMachine::Hooks, '#register' do
  let(:object) { described_class }

  subject(:hooks) { object.new }

  it "adds and removes a single hook" do
    expect(hooks).to be_empty

    event_type = FiniteMachine::HookEvent::Before
    hook = -> { }

    hooks.register(event_type, :foo, hook)
    expect(hooks.collection).to eq({event_type => {foo: [hook]}})

    hooks.unregister(event_type, :foo, hook)
    expect(hooks.collection).to eq({event_type => {foo: []}})
  end
end
