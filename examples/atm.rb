$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'finite_machine'

class Account
  attr_accessor :number

  def verify(account_number, pin)
    return account_number == 123456 && pin == 666
  end
end

account = Account.new

atm = FiniteMachine.define do
  initial :unauthorized

  target account

  events {
    event :authorize, :unauthorized => :authorized, if: -> (account, account_number, pin) {
      account.verify(account_number, pin)
    }
    event :deauthorize, :authorized => :unauthorized
  }

  callbacks {
    on_exit :unauthorized do |event, account_number, pin|
      # if verify(account_number, pin)
        self.number = account_number
#       else
#         puts "Invalid Account and/or PIN"
#         FiniteMachine::CANCELLED
#       end
    end
  }
end

atm.authorize(111222, 666)
puts "authorized: #{atm.authorized?}"
puts "Number: #{account.number}"

atm.authorize(123456, 666)
puts "authorized: #{atm.authorized?}"
puts "Number: #{account.number}"
