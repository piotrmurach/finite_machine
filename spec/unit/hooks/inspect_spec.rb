# encoding: utf-8

require 'spec_helper'

RSpec.describe FiniteMachine::Hooks, '#inspect' do
  subject(:hooks) { described_class.new }

  it "displays name and transitions" do
    hook = -> { }
    event = FiniteMachine::HookEvent::Enter
    collection = {event => {yellow: [hook]}}
    hooks.register(event, :yellow, hook)

    expect(hooks.inspect).to eql("<#FiniteMachine::Hooks:0x#{hooks.object_id.to_s(16)} @collection=#{collection}>")
    expect(hooks.to_s).to eql(hooks.inspect)
  end
end
