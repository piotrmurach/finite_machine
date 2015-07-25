# encoding: utf-8

require 'spec_helper'

RSpec.describe FiniteMachine, '.event_names' do
  it "retrieves all event names" do
    fsm = FiniteMachine.define do
      initial :green

      events {
        event :start, :red => :green
        event :stop,  :green => :red
      }
    end

    expect(fsm.current).to eql(:green)
    expect(fsm.event_names).to eql([:init, :start, :stop])
  end
end
