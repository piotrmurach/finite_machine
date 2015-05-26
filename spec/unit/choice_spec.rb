# encoding: utf-8

require 'spec_helper'

RSpec.describe FiniteMachine, '#choice' do
  before(:each) {
    stub_const("User", Class.new do
      def promo?(token = false)
        token == :yes
      end
    end)
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

  it "groups correctly events under the same name" do
    fsm = FiniteMachine.define do
      initial :red

      event :next, from: :yellow, to: :green

      event :next, from: :red do
        choice :pink, if: -> { false }
        choice :yellow
      end
    end
    expect(fsm.current).to eq(:red)
    fsm.next
    expect(fsm.current).to eq(:yellow)
    fsm.next
    expect(fsm.current).to eq(:green)
  end

  it "performs matching transitions for multiple event definitions with the same name" do
    ticket = double(:ticket, :pending? => true, :finished? => true)
    fsm = FiniteMachine.define do
      initial :inactive

      target ticket

      events {
        event :advance, from: [:inactive, :paused, :fulfilled] do
          choice :active, if: proc { |_ticket| !_ticket.pending? }
        end

        event :advance, from: [:inactive, :active, :fulfilled] do
          choice :paused, if: proc { |_ticket| _ticket.pending? }
        end

        event :advance, from: [:inactive, :active, :paused] do
          choice :fulfilled, if: proc { |_ticket| _ticket.finished? }
        end
      }
    end
    expect(fsm.current).to eq(:inactive)
    fsm.advance
    expect(fsm.current).to eq(:paused)
    fsm.advance
    expect(fsm.current).to eq(:fulfilled)
  end

  it "does not transition when no matching choice for multiple event definitions" do
    ticket = double(:ticket, :pending? => true, :finished? => false)
    fsm = FiniteMachine.define do
      initial :inactive

      target ticket

      events {
        event :advance, from: [:inactive, :paused, :fulfilled] do
          choice :active, if: proc { |_ticket| !_ticket.pending? }
        end

        event :advance, from: [:inactive, :active, :fulfilled] do
          choice :paused, if: proc { |_ticket| _ticket.pending? }
        end

        event :advance, from: [:inactive, :active, :paused] do
          choice :fulfilled, if: proc { |_ticket| _ticket.finished? }
        end
      }
    end
    expect(fsm.current).to eq(:inactive)
    fsm.advance
    expect(fsm.current).to eq(:paused)
    fsm.advance
    expect(fsm.current).to eq(:paused)
  end

  it "sets callback properties correctly" do
    expected = {name: :init, from: :none, to: :red, a: nil, b: nil, c: nil }

    callback = Proc.new { |event, a, b, c|
      target.expect(event.from).to target.eql(expected[:from])
      target.expect(event.to).to target.eql(expected[:to])
      target.expect(event.name).to target.eql(expected[:name])
      target.expect(a).to target.eql(expected[:a])
      target.expect(b).to target.eql(expected[:b])
      target.expect(c).to target.eql(expected[:c])
    }

    context = self

    fsm = FiniteMachine.define do
      initial :red

      target context

      events {
        event :next, from: :red do
          choice :green, if: -> { false }
          choice :yellow
        end

        event :next, from: :yellow do
          choice :green, if: -> { true }
          choice :yellow
        end

        event :finish, from: :any do
          choice :green, if: -> { false }
          choice :red
        end
      }

      callbacks {
        # generic state callbacks
        on_enter(&callback)
        on_transition(&callback)
        on_exit(&callback)

        # generic event callbacks
        on_before(&callback)
        on_after(&callback)

        # state callbacks
        on_enter :green,  &callback
        on_enter :yellow, &callback
        on_enter :red,    &callback

        on_transition :green,  &callback
        on_transition :yellow, &callback
        on_transition :red,    &callback

        on_exit :green,  &callback
        on_exit :yellow, &callback
        on_exit :red,    &callback

        # event callbacks
        on_before :next, &callback
        on_after  :next, &callback
      }
    end
    expect(fsm.current).to eq(:red)

    expected = {name: :next, from: :red, to: :yellow, a: 1, b: 2, c: 3}
    fsm.next(1, 2, 3)

    expected = {name: :next, from: :yellow, to: :green, a: 4, b: 5, c: 6}
    fsm.next(4, 5, 6)

    expected = {name: :finish, from: :green, to: :red, a: 7, b: 8, c: 9}
    fsm.finish(7, 8, 9)
  end
end
