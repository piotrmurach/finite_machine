# frozen_string_literal: true

require_relative "../lib/finite_machine"

class Account
  attr_accessor :message

  def verify(account_number, pin)
    account_number == 123456 && pin == 666
  end
end

account = Account.new

ATM = FiniteMachine.define do
  alias_target :account

  initial :unauthorized

  event :authorize, :unauthorized => :authorized
  event :deauthorize, :authorized => :unauthorized

  on_exit :unauthorized do |event, account_number, pin|
    if account.verify(account_number, pin)
      account.message = "Welcome to your Account"
    else
      account.message = "Invalid Account and/or PIN"
      cancel_event
    end
  end
end

atm = ATM.new(account)

atm.authorize(111222, 666)
puts "authorized: #{atm.authorized?}"
puts "Number: #{account.message}"

atm.authorize(123456, 666)
puts "authorized: #{atm.authorized?}"
puts "Number: #{account.message}"
