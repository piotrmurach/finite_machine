# frozen_string_literal: true

RSpec.describe FiniteMachine::Hooks, '#call' do
  it "adds and removes a single hook" do
    hooks = FiniteMachine::Hooks.new
    expect(hooks).to be_empty

    yielded = []
    event_type = FiniteMachine::HookEvent::Before
    hook = -> { }
    hooks.register(event_type, :foo, hook)

    hooks[event_type][:foo].each do |callback|
      yielded << callback
    end

    expect(yielded).to eq([hook])
  end
end
