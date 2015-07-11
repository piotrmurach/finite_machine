# encoding: utf-8

require 'spec_helper'

RSpec.describe FiniteMachine::HookEvent, '.notify' do
  it "triggers event on the subscriber" do
    subscriber = spy(:subscriber)
    transition = double(:transition)
    hook_event = described_class.new(:green, transition)

    hook_event.notify(subscriber, 1, 2)

    expect(subscriber).to have_received(:trigger).with(hook_event, 1, 2)
  end
end
