# encoding: utf-8

require 'spec_helper'

describe FiniteMachine, '#inspect' do

  it "print useful information about state machine" do
    fsm = FiniteMachine.define do
      initial :green

      events {
        event :slow,  :green  => :yellow
        event :stop,  :yellow => :red
      }
    end
    expect(fsm.inspect).to match(/^<#FiniteMachine::StateMachine:0x#{fsm.object_id.to_s(16)} @states=\[:none, :green, :yellow, :red\], @events=\[:init, :slow, :stop\], @transitions=.*$/)
  end
end
