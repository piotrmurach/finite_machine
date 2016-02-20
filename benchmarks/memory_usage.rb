# encoding: utf-8

require 'finite_machine'

3.times do
  puts

  GC.start

  before = GC.stat
  p ObjectSpace.count_objects

  1_000.times do
    FiniteMachine.define
  end

  p ObjectSpace.count_objects
  after = GC.stat

  p "GC count: #{after[:count] - before[:count]}"
end
