# encoding: utf-8

require 'spec_helper'

RSpec.describe FiniteMachine, 'states' do
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

    expect(fsm.states).to match_array([:none, :green, :yellow, :red])
  end

  it "retrieves all unique states for choice transition" do
    fsm = FiniteMachine.define do
      initial :green

      events {
        event :next, from: :green do
          choice :yellow, if: -> { false }
          choice :red,    if: -> { true }
        end
      }
    end
    expect(fsm.states).to match_array([:none, :green, :yellow, :red])
  end
end
