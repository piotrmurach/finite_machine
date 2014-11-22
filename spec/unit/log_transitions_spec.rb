# encoding: utf-8

require 'spec_helper'

RSpec.describe FiniteMachine, 'log_transitions' do
  let(:output) { StringIO.new('', 'w+')}

  before { FiniteMachine.logger = ::Logger.new(output) }

  after  { FiniteMachine.logger = ::Logger.new($stderr) }

  it "logs transitions" do
    fsm = FiniteMachine.define log_transitions: true do
      initial :green

      events {
        event :slow, :green  => :yellow
        event :stop, :yellow => :red
      }
    end

    fsm.slow
    output.rewind
    expect(output.read).to match(/Transition: @event=slow green -> yellow/)

    fsm.stop(1, 2)
    output.rewind
    expect(output.read).to match(/Transition: @event=stop @with=\[1,2\] yellow -> red/)
  end
end
