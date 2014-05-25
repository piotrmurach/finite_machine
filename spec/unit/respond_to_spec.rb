# encoding: utf-8

require 'spec_helper'

describe FiniteMachine, '#respond_to' do

  subject(:fsm) {
    Car = Class.new do
      def engine_on?
        true
      end
    end
    FiniteMachine.new target: Car.new do
      initial :green

      events {
        event :slow,  :green  => :yellow
      }
    end
  }

  it "knows about event name" do
    expect(fsm).to respond_to(:slow)
  end

  it "doesn't know about not implemented call" do
    expect(fsm).not_to respond_to(:not_implemented)
  end

  it "knows about event callback" do
    expect(fsm).to respond_to(:on_enter_slow)
  end

  it "knows about target class methods" do
    expect(fsm).to respond_to(:engine_on?)
  end
end
