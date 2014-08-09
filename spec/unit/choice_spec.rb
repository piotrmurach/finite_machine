# encoding: utf-8

require 'spec_helper'

describe FiniteMachine, '#choice' do
  before(:each) {
    User = Class.new do
      def promo?(token = false)
        token == :yes
      end
    end
  }

  it "allows for static choice based on conditional branching" do
    called = []
    fsm = FiniteMachine.define do
      initial :company_form

      events {
        event :next, from: :company_form do
          choice :agreement_form, if: -> { false }
          choice :promo_form,     if: -> { false }
          choice :official_form,  if: -> { true }
        end
      }

      callbacks {
        on_exit  do |event| called << "on_exit_#{event.from}" end
        on_enter do |event| called << "on_enter_#{event.to}"  end
      }
    end
    expect(fsm.current).to eq(:company_form)
    fsm.next
    expect(fsm.current).to eq(:official_form)
    expect(called).to eq([
      'on_exit_company_form',
      'on_enter_official_form'
    ])
  end

  it "allows for dynamic choice based on conditional branching" do
    fsm = FiniteMachine.define do
      initial :company_form

      events {
        event :next, from: :company_form do
          choice :agreement_form, if: proc { |_, a| a < 1 }
          choice :promo_form,     if: proc { |_, a| a == 1 }
          choice :official_form,  if: proc { |_, a| a > 1 }
        end
      }
    end
    expect(fsm.current).to eq(:company_form)
    fsm.next(0)
    expect(fsm.current).to eq(:agreement_form)

    fsm.restore!(:company_form)
    fsm.next(1)
    expect(fsm.current).to eq(:promo_form)

    fsm.restore!(:company_form)
    fsm.next(2)
    expect(fsm.current).to eq(:official_form)
  end

  it "allows for dynamic choice based on conditional branching and target" do
    user = User.new
    fsm = FiniteMachine.define do
      initial :company_form

      target user

      events {
        event :next, from: :company_form do
          choice :agreement_form, if: proc { |_user, token| _user.promo?(token) }
          choice :promo_form, unless: proc { |_user, token| _user.promo?(token) }
        end
      }
    end
    expect(fsm.current).to eq(:company_form)
    fsm.next(:no)
    expect(fsm.current).to eq(:promo_form)
    fsm.restore!(:company_form)
    fsm.next(:yes)
    expect(fsm.current).to eq(:agreement_form)
  end

  it "choses state when skipped if/unless" do
    fsm = FiniteMachine.define do
      initial :company_form

      events {
        event :next, from: :company_form do
          choice :agreement_form, if: -> { false }
          choice :promo_form
          choice :official_form,  if: -> { true }
        end
      }
    end
    expect(fsm.current).to eq(:company_form)
    fsm.next
    expect(fsm.current).to eq(:promo_form)
  end

  it "choice default state when branching conditions don't match" do
    fsm = FiniteMachine.define do
      initial :company_form

      events {
        event :next, from: :company_form do
          choice :agreement_form, if: -> { false }
          choice :promo_form,     if: -> { false }
          default :official_form
        end
      }
    end
    expect(fsm.current).to eq(:company_form)
    fsm.next
    expect(fsm.current).to eq(:official_form)
  end

  it "fails to transition when no condition matches without default state" do
    fsm = FiniteMachine.define do
      initial :company_form

      events {
        event :next, from: :company_form do
          choice :agreement_form, if: -> { false }
          choice :promo_form,     if: -> { false }
        end
      }
    end
    expect(fsm.current).to eq(:company_form)
    fsm.next
    expect(fsm.current).to eq(:company_form)
  end

  it "allows to transition from multiple states to choice pseudostate" do
    fsm = FiniteMachine.define do
      initial :red

      event :go, from: [:yellow, :red] do
        choice :pink, if: -> { false }
        choice :green
      end
    end
    expect(fsm.current).to eq(:red)
    fsm.go
    expect(fsm.current).to eq(:green)
    fsm.restore!(:yellow)
    expect(fsm.current).to eq(:yellow)
    fsm.go
    expect(fsm.current).to eq(:green)
  end

  it "allows to transition from any state to choice pseudo state" do
    fsm = FiniteMachine.define do
      initial :red

      event :go, from: :any do
        choice :pink, if: -> { false }
        choice :green
      end
    end
    expect(fsm.current).to eq(:red)
    fsm.go
    expect(fsm.current).to eq(:green)
  end
end
