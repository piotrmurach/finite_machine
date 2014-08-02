# encoding: utf-8

require 'spec_helper'

describe FiniteMachine::HookEvent, 'new' do
  let(:name)       { :green }
  let(:transition) { double(:transition) }
  let(:data)       { [:foo, :bar] }
  let(:object)     { described_class }

  subject(:hook) { object.new(name, transition, *data) }

  it "exposes readers" do
    expect(hook.name).to eql(name)
    expect(hook.data).to eql(data)
    expect(hook.type).to eql(object)
  end

  it "freezes object" do
    expect { hook.name = :red }.to raise_error(RuntimeError)
  end
end
