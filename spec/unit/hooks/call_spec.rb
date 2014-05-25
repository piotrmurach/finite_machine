# encoding: utf-8

require 'spec_helper'

describe FiniteMachine::Hooks, '#call' do
  let(:object) { described_class }

  subject(:hooks) { object.new }

  it "adds and removes a single hook" do
    expect(hooks).to be_empty

    yielded = []
    event_type = FiniteMachine::HookEvent::Before
    hook = -> { }
    hooks.register(event_type, :foo, hook)

    hooks.call(event_type, :foo) do |callback|
      yielded << callback
    end

    expect(yielded).to eq([hook])
  end
end
