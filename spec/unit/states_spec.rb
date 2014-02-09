# encoding: utf-8

require 'spec_helper'

describe FiniteMachine, 'states' do

  it "retrieves all available states" do
    fsm = FiniteMachine.define do
      initial :green

      events {
        event :slow,  :green  => :yellow
        event :stop,  :yellow => :red
        event :ready, :red    => :yellow
        event :go,    :yellow => :green
      }
    end

    expect(fsm.states).to eql([:none, :green, :yellow, :red])
  end
end
