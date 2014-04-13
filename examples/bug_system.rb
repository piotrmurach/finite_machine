$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'finite_machine'

class User
  attr_accessor :name

  def initialize(name)
    @name = name
  end
end

class Manager < User
  attr_accessor :developers

  def initialize(name)
    super
    @developers = []
  end

  def manages(developer)
    @developers << developer
  end

  def assign(bug)
    developer = @developers.first
    bug.assign
    developer.bug = bug
  end
end

class Tester < User
  def report(bug)
    bug.report
  end

  def reopen(bug)
    bug.reopen
  end
end

class Developer < User
  attr_accessor :bug

  def work_on
    bug.start
  end

  def resolve
    bug.close
  end
end

class BugSystem
  attr_accessor :managers

  def initialize(managers = [])
    @managers = managers
  end

  def notify_manager(bug)
    manager = @managers.first
    manager.assign(bug)
  end
end

class Bug
  attr_accessor :name
  attr_accessor :priority
  # fake belongs_to relationship
  attr_accessor :bug_system

  def initialize(name, priority)
    @name = name
    @priority = priority
  end

  def report
    status.report
  end

  def assign
    status.assign
  end

  def start
    status.start
  end

  def close
    status.close
  end

  def reopen
    status.reopen
  end

  def status
    context = self
    @status ||= FiniteMachine.define do
      target context

      events {
        event :report, :none => :new
        event :assign, :new => :assigned
        event :start,  :assigned => :in_progress
        event :close,  [:in_progress, :reopened] => :resolved
        event :reopen, :resolved => :reopened
      }

      callbacks {
        on_enter :new do |event|
          bug_system.notify_manager(self)
        end
      }
    end
  end
end

tester    = Tester.new("John")
manager   = Manager.new("David")
developer = Developer.new("Piotr")
manager.manages(developer)

bug_system = BugSystem.new([manager])
bug        = Bug.new(:trojan, :high)
bug.bug_system = bug_system

puts "A BUG's LIFE"
puts "#1 #{bug.status.current}"

tester.report(bug)
puts "#2 #{bug.status.current}"

developer.work_on
puts "#3 #{bug.status.current}"

developer.resolve
puts "#4 #{bug.status.current}"

tester.reopen(bug)
puts "#5 #{bug.status.current}"

developer.resolve
puts "#6 #{bug.status.current}"
