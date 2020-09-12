# frozen_string_literal: true

require_relative "../lib/finite_machine"

class Engine
  def initialize
    @engine = false
  end

  def turn_off
    @engine = false
  end

  def turn_on
    @engine = true
  end

  def engine_on?
    @engine
  end
end

Car = FiniteMachine.define do
  alias_target :engine

  initial :neutral

  event :ignite, :neutral => :one, unless: "engine_on?"
  event :stop, :one => :neutral, if: "engine_on?"

  on_before_ignite { |event| engine.turn_on }
  on_after_stop { |event| engine.turn_off }
end

engine = Engine.new
car = Car.new(engine)

puts "Engine on?: #{engine.engine_on?}"
car.ignite
puts "Engine on?: #{engine.engine_on?}"
