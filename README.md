# FiniteMachine
[![Gem Version](https://badge.fury.io/rb/finite_machine.png)][gem]
[![Build Status](https://secure.travis-ci.org/peter-murach/finite_machine.png?branch=master)][travis]
[![Code Climate](https://codeclimate.com/github/peter-murach/finite_machine.png)][codeclimate]

[gem]: http://badge.fury.io/rb/finite_machine
[travis]: http://travis-ci.org/peter-murach/finite_machine
[codeclimate]: https://codeclimate.com/github/peter-murach/finite_machine

A minimal finite state machine with a straightforward and intuitive syntax. You can quickly model states and add callbacks that can be triggered synchronously or asynchronously.

## Features

* plain object state machine
* easy custom object integration
* natural DSL for declaring events, exceptions and callbacks
* observers (pub/sub) for state changes
* ability to check reachable states
* ability to check for terminal state
* conditional transitions
* sync and async callbacks (TODO - only sync)
* nested/composable states (TODO)

## Installation

Add this line to your application's Gemfile:

    gem 'finite_machine'

Then execute:

    $ bundle

Or install it yourself as:

    $ gem install finite_machine

## 1 Usage

Here is a very simple example of a state machine:

```ruby
fm = FiniteMachine.define do
  initial :red

  events {
    event :ready, :red    => :yellow
    event :go,    :yellow => :green
    event :stop,  :green  => :red
  }

  callbacks {
    on_enter :ready { |event| ... }
    on_enter :go    { |event| ... }
    on_enter :stop  { |event| ... }
  }
end
```

As the example demonstrates, by calling the `define` method on **FiniteMachine** you create an instance of finite state machine. The `events` and `callbacks` scopes help to define the behaviour of the machine. Read [Transitions](#2-transitions) and [Callbacks](#4-callbacks) sections for more details.

### 1.1 current

The **FiniteMachine** allows you to query the current state by calling the `current` method.

```ruby
  fm.current  # => :red
```

### 1.2 initial

There are number of ways to provide the initial state  **FiniteMachine** depending on your requirements.

By default the **FiniteMachine** will be in the `:none` state and you will need to provide an event to transition out of this state.

```ruby
  fm = FiniteMachine.define do
    events {
      event :start, :none   => :green
      event :slow,  :green  => :yellow
      event :stop,  :yellow => :red
    }
  end

  fm.current # => :none
```

If you specify initial state using the `initial` helper, an `init` event will be created and triggered when the state machine is created.

```ruby
  fm = FiniteMachine.define do
    initial :green

    events {
      event :slow,  :green  => :yellow
      event :stop,  :yellow => :red
    }
  end

  fm.current # => :green
```

If you want to defer calling the initial state method pass the `:defer` option to the `initial` helper.

```ruby
  fm = FiniteMachine.define do
    initial state: :green, defer: true

    events {
      event :slow,  :green  => :yellow
      event :stop,  :yellow => :red
    }
  end
  fm.current # => :none
  fm.init
  fm.current # => :green
```

### 1.3 terminal

To specify a final state **FiniteMachine** uses the `terminal` method.

```ruby
  fm = FiniteMachine.define do
    initial :green
    terminal :red

    events {
      event :slow, :green  => :yellow
      event :stop, :yellow => :red
    }
  end
```

When the terminal state has been specified, you can use `finished?` method on the state machine instance to verify if the terminal state has been reached or not.

```ruby
  fm.finished?  # => false
  fm.slow
  fm.finished?  # => false
  fm.stop
  fm.finished?  # => true
```

### 1.4 is?

To verify whether or not a state machine is in a given state, **FiniteMachine** uses `is?` method. It returns `true` if the machine is found to be in the given state, or `false` otherwise.

```ruby
  fm.is?(:red)    # => true
  fm.is?(:yellow) # => false
```

### 1.5 can? and cannot?

To verify whether or not an event can be fired, **FiniteMachine** provides `can?` or `cannot?` methods. `can?` checks if **FiniteMachine** can fire a given event, returning true, otherwise, it will return false. `cannot?` is simply the inverse of `can?`.

```ruby
  fm.can?(:ready)    # => true
  fm.can?(:go)       # => false
  fm.cannot?(:ready) # => false
  fm.cannot?(:go)    # => true
```

### 1.6 states

You can use the `states` method to return an array of all the states for a given state machine.

```ruby
  fm.states # => [:none, :green, :yellow, :red]
```

### 1.7 target

If you need to execute some external code in the context of the current state machine use `target` helper.

```ruby
  car = Car.new

  fm = FiniteMachine.define do
    initial :neutral

    target car

    events {
      event :start, :neutral => :one, if: "engine_on?"
      event :shift, :one => :two
    }
  end
```

## 2 Transitions

The `events` scope exposes the `event` helper to define possible state transitions.

The `event` helper accepts as a first parameter the name which will later be used to create
method on the **FiniteMachine** instance. As a second parameter `event` accepts an arbitrary number of states either
in the form of `:from` and `:to` hash keys or by using the state names themselves as key value pairs.

```ruby
  event :start, from: :neutral, to: :first
  or
  event :start, :neutral => :first
```

Once specified, the **FiniteMachine** will create custom methods for transitioning between each state.
The following methods trigger transitions for the example state machine.

* ready
* go
* stop

### 2.1 Performing transitions

In order to transition to the next reachable state, simply call the event's name on the **FiniteMachine** instance.

```ruby
  fm.ready
  fm.current       # => :yellow
```

Furthermore, you can pass additional parameters with the method call that will be available in the triggered callback.

```ruby
  fm.go('Piotr!')
  fm.current       # => :green
```

### 2.2 single event with multiple from states

If an event transitions from multiple states to the same state then all the states can be grouped into an array.
Altenatively, you can create separte events under the same name for each transition that needs combining.

```ruby
fm = FiniteMachine.define do
  initial :neutral

  events {
    event :start,  :neutral             => :one
    event :shift,  :one                 => :two
    event :shift,  :two                 => :three
    event :shift,  :three               => :four
    event :slow,   [:one, :two, :three] => :one
  }
end
```

## 3 Conditional transitions

Each event takes an optional `:if` and `:unless` options which act as a predicate for the transition. The `:if` and `:unless` can take a symbol, a string, a Proc or an array. Use `:if` option when you want to specify when the transition **should** happen. If you want to specify when the transition **should not** happen then use `:unless` option.

### 3.1 Using a Proc

You can associate the `:if` and `:unless` options with a Proc object that will get called right before transition happens. Proc object gives you ability to write inline condition instead of separate method.

```ruby
  fm = FiniteMachine.define do
    initial :green

    events {
      event :slow, :green => :yellow, if: -> { return false }
    }
  end
  fm.slow    # doesn't transition to :yellow state
  fm.current # => :green
```

You can also execute methods on an associated object by passing it as an argument to `target` helper.

```ruby
  class Car
    def turn_engine_on
      @engine_on = true
    end

    def turn_engine_off
      @engine_on = false
    end

    def engine_on?
      @engine_on
    end
  end

  car = Car.new
  car.trun_engine_on

  fm = FiniteMachine.define do
    initial :neutral

    target car

    events {
      event :start, :neutral => :one, if: "engine_on?"
    }
  end

  fm.start
  fm.current # => :one
```

### 3.2 Using a Symbol

You can also use a symbol corresponding to the name of a method that will get called right before transition happens.

```ruby
  fsm = FiniteMachine.define do
    initial :neutral

    target car

    events {
      event :start, :neutral => :one, if: :engine_on?
    }
  end
```

### 3.3 Using a String

Finally, it's possible to use string that will be evaluated using `eval` and needs to contain valid Ruby code. It should only be used when the string represents a short condition.

```ruby
  fsm = FiniteMachine.define do
    initial :neutral

    target car

    events {
      event :start, :neutral => :one, if: "engine_on?"
    }
  end
```

### 3.4 Combining transition conditions

When multiple conditions define whether or not a transition should happen, an Array can be used. Furthermore, you can apply both `:if` and `:unless` to the same transition.

```ruby
  fsm = FiniteMachine.define do
    initial :green

    events {
      event :slow, :green => :yellow,
        if: [ -> { return true }, -> { return true} ],
        unless: -> { return true }
      event :stop, :yellow => :red
    }
  end
```

The transition only runs when all the `:if` conditions and none of the `unless` conditions are evaluated to `true`.

## 4 Callbacks

You can watch state machine events and the information they provide by registering a callback. The following 3 types of callbacks are available in **FiniteMachine**:

* `on_enter`
* `on_transition`
* `on_exit`

Use the `callbacks` scope to introduce the listeners. You can register a callback to listen for state changes or events being triggered. Use the state or event name as a first parameter to the callback followed by a list arguments that you expect to receive.

When you subscribe to the `:green` state event, the callback will be called whenever someone instruments change for that state. The same will happend on subscription to event `ready`, namely, the callback will be called each time the state transition method is called.

```ruby
fm = FiniteMachine.define do
  initial :red

  events {
    event :ready, :red    => :yellow
    event :go,    :yellow => :green
    event :stop,  :green  => :red
  }

  callbacks {
    on_enter :ready { |event, time1, time2, time3| puts "#{time1} #{time2} #{time3} Go!" }
    on_enter :go    { |event, name| puts "Going fast #{name}" }
    on_enter :stop  { |event| ... }
  }
end

fm.ready(1, 2, 3)
fm.go('Piotr!')
```

### 4.1 on_enter

This method is executed before given event or state change. If you provide only a callback without the name of the state or event to listen out for, then `:any` state and `:any` event will be observered.

### 4.2 on_transition

This method is executed when given event or state change happens. If you provide only a callback without the name of the state or event to listen out for, then `:any` state and `:any` event will be observered.

### 4.3 on_exit

This method is executed after a given event or state change happens. If you provide only a callback without the name of the state or event to listen for, then `:any` state and `:any` event will be observered.

### 4.4 Parameters

All callbacks get the `TransitionEvent` object with the following attributes.

* name    # the event name
* from    # the state transitioning from
* to      # the state transitioning to

followed by the rest of arguments that were passed to the event method.

### 4.5 Same kind of callbacks

You can define any number of the same kind of callback. These callbacks will be executed in the order they are specified.

```ruby
  fm = FiniteMachine.define do
    initial :green

    events {
      event :slow, :green => :yellow
    }

    callbacks {
      on_enter(:yellow) { this_is_run_first }
      on_enter(:yellow) { then_this }
    }
  end
  fm.slow # => will invoke both callbacks
```

### 4.6 Fluid callbacks

Callbacks can also be specified as full method calls.

```ruby
fm = FiniteMachine.define do
  initial :red

  events {
    event :ready, :red    => :yellow
    event :go,    :yellow => :green
    event :stop,  :green  => :red
  }

  callbacks {
    on_enter_ready { |event| ... }
    on_enter_go    { |event| ... }
    on_enter_stop  { |event| ... }
  }
end
```

## 5 Errors

## 6 Integration

Since **FiniteMachine** is an object in its own right it leaves integration with other systems up to you. In contrast to other Ruby libraries, it does not extend from models (i.e. ActiveRecord) to transform them into a state machine or require mixing into exisiting classes.

```ruby

class Car
  attr_accessor :reverse_lights

  def turn_reverse_lights_off
    reverse_lights = false
  end

  def turn_reverse_lights_on
    reverse_lights = true
  end

  def gears
    @gears ||= FiniteMachine.define do
      initial :neutral

      target: self

      events {
        event :start, :neutral => :one
        event :shift, :one => :two
        event :shift, :two => :one
        event :back,  [:neutral, :one] => :reverse
      }

      callbacks {
        on_enter :reverse do |car, event|
          car.turnReverseLightsOn
        end

        on_exit :reverse do |car, event|
          car.turnReverseLightsOff
        end

        on_transition do |car, event|
          puts "shifted from #{event.from} to #{event.to}"
        end
      }
    end
  end
end

```

## 7 Tips

Creating a standalone **FiniteMachine** brings few benefits, one of them being easier testing. This is especially true if the state machine is extremely complex itself.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Copyright

Copyright (c) 2014 Piotr Murach. See LICENSE for further details.
