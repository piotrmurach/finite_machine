# FiniteMachine
[![Gem Version](https://badge.fury.io/rb/finite_machine.png)][gem]
[![Build Status](https://secure.travis-ci.org/peter-murach/finite_machine.png?branch=master)][travis]
[![Code Climate](https://codeclimate.com/github/peter-murach/finite_machine.png)][codeclimate]
[![Coverage Status](https://coveralls.io/repos/peter-murach/finite_machine/badge.png)][coverage]
[![Inline docs](http://inch-pages.github.io/github/peter-murach/finite_machine.png)][inchpages]

[gem]: http://badge.fury.io/rb/finite_machine
[travis]: http://travis-ci.org/peter-murach/finite_machine
[codeclimate]: https://codeclimate.com/github/peter-murach/finite_machine
[coverage]: https://coveralls.io/r/peter-murach/finite_machine
[inchpages]: http://inch-pages.github.io/github/peter-murach/finite_machine

A minimal finite state machine with a straightforward and intuitive syntax. You can quickly model states and add callbacks that can be triggered synchronously or asynchronously. The machine is event driven with a focus on passing synchronous and asynchronous messages to trigger state transitions.

## Features

* plain object state machine
* easy custom object integration
* natural DSL for declaring events, exceptions and callbacks
* observers (pub/sub) for state changes
* ability to check reachable states
* ability to check for terminal state
* conditional transitions
* sync and async transitions
* sync and async callbacks (TODO - only sync)
* nested/composable states (TODO)

## Installation

Add this line to your application's Gemfile:

    gem 'finite_machine'

Then execute:

    $ bundle

Or install it yourself as:

    $ gem install finite_machine

## Contents

* [1. Usage](#1-usage)
* [2. Transitions](#2-transitions)
* [3. Conditional transitions](#3-conditional-transitions)
* [4. Callbacks](#4-callbacks)
* [5. Errors](#5-errors)
* [6. Integration](#6-integration)
* [7. Tips](#7-tips)

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
fm.start
fm.current # => :green
```

If you specify initial state using the `initial` helper, the state machine will be created already in that state.

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

If you want to defer setting the initial state, pass the `:defer` option to the `initial` helper. By default **FiniteMachine** will create `init` event that will allow to transition from `:none` state to the new state.

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

If your target object already has `init` method or one of the events names redefines `init`, you can use different name by passing `:event` option to `initial` helper.

```ruby
fm = FiniteMachine.define do
  initial state: :green, event: :start, defer: true

  events {
    event :slow,  :green  => :yellow
    event :stop,  :yellow => :red
  }
end

fm.current # => :none
fm.start
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

Moreover, you can use helper methods to check for current state using the state name itself like so

```ruby
fm.red?     # => true
fm.yellow?  # => false
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

Furthermore, the context created through `target` helper will allow you to reference and call methods from another object.

```ruby
car = Car.new

fm = FiniteMachine.define do
  initial :neutral

  target car

  events {
    event :start, :neutral => :one, if: "engine_on?"
  }

  callbacks {
    on_enter_start do |event| turn_engine_on end
    on_exit_start  do |event| turn_engine_off end
  }
end
```

For more complex example see [Integration](#6-integration) section.

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

### 2.2 Asynchronous transitions

By default the transitions will be fired synchronosuly.

```ruby
fm.ready
or
fm.sync.ready
fm.current     # => :yellow
```

In order to fire the event transition asynchronously use the `async` scope like so

```ruby
fm.async.ready  # => executes in separate Thread
```

### 2.3 single event with multiple from states

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

Provided your **FiniteMachine** is associated with another object through `target` helper. Then the target object together with event arguments will be passed to the `:if` or `:unless` condition scope.

```ruby
class Car
  attr_accessor :engine_on

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
car.turn_engine_on

fm = FiniteMachine.define do
  initial :neutral

  target car

  events {
    event :start, :neutral => :one, if: -> (_car, state) {
      _car.engine_on = state
      _car.engine_on?
    }
  }
end

fm.start(false)
fm.current       # => :neutral
fm.start(true)
fm.current       # => :one
```

When the one-liner conditions are not enough for your needs, you can perform conditional logic inside the callbacks. See [4.10 Cancelling inside callbacks](#410-cancellig-inside-callbacks)

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

In addition, you can listen for generic state changes or events fired by using the following 6 callbacks:

* `on_enter_state`
* `on_enter_event`
* `on_transition_state`
* `on_transition_event`
* `on_exit_state`
* `on_exit_event`

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

You can further narrow down the listener to only watch enter state changes using `on_enter_state` callback. Similarly, use `on_enter_event` to only watch for event changes.

### 4.2 on_transition

This method is executed when given event or state change happens. If you provide only a callback without the name of the state or event to listen out for, then `:any` state and `:any` event will be observered.

You can further narrow down the listener to only watch state transition changes using `on_transition_state` callback. Similarly, use `on_transition_event` to only watch for event transition changes.

### 4.3 on_exit

This method is executed after a given event or state change happens. If you provide only a callback without the name of the state or event to listen for, then `:any` state and `:any` event will be observered.

You can further narrow down the listener to only watch state exit changes using `on_exit_state` callback. Similarly, use `on_exit_event` to only watch for event exit changes.

### 4.4 once_on

**FiniteMachine** allows you to listen on initial state change or when the event is fired first time by using the following 3 types of callbacks:

* `once_on_enter`
* `once_on_transition`
* `once_on_exit`

### 4.5 Parameters

All callbacks get the `TransitionEvent` object with the following attributes.

* `name    # the event name`
* `from    # the state transitioning from`
* `to      # the state transitioning to`

followed by the rest of arguments that were passed to the event method.

```ruby
fm = FiniteMachine.define do
  initial :red

  events {
    event :ready, :red => :yellow
  }

  callbacks {
    on_enter_ready { |event, time|
      puts "lights switching from #{event.from} to #{event.to} in #{time} seconds"
    }
  }
end

fm.ready(3)   #  => 'lights switching from red to yellow in 3 seconds'
```

### 4.6 Same kind of callbacks

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

### 4.7 Fluid callbacks

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

### 4.8 Executing methods inside callbacks

In order to execute method from another object use `target` helper.

```ruby
class Car
  attr_accessor :reverse_lights

  def turn_reverse_lights_off
    @reverse_lights = false
  end

  def turn_reverse_lights_on
    @reverse_lights = true
  end
end

car = Car.new

fm = FiniteMachine.define do
  initial :neutral

  target car

  events {
    event :forward, [:reverse, :neutral] => :one
    event :back,    [:neutral, :one] => :reverse
  }

  callbacks {
    on_enter_reverse { |event| turn_reverse_lights_on }
    on_exit_reverse  { |event| turn_reverse_lights_off }
  }
end
```

Note that you can also fire events from callbacks.

```ruby
fm = FiniteMachine.define do
  initial :neutral

  target car
events {
    event :forward, [:reverse, :neutral] => :one
    event :back,    [:neutral, :one] => :reverse
  }

  callbacks {
    on_enter_reverse { |event| forward('Piotr!') }
    on_exit_reverse  { |event, name| puts "Go #{name}" }
  }
end
fm.back   # => Go Piotr!
```

For more complex example see [Integration](#6-integration) section.

### 4.9 Defining callbacks

When defining callbacks you are not limited to the `callbacks` helper. After **FiniteMachine** instance is created you can register callbacks the same way as before by calling `on` and supplying the type of notification and state/event you are interested in.

```ruby
fm = FiniteMachine.define do
  initial :red

  events {
    event :ready, :red    => :yellow
    event :go,    :yellow => :green
    event :stop,  :green  => :red
  }
end

fm.on_enter_yellow do |event|
  ...
end
```

### 4.10 Cancelling inside callbacks

Preferred way to handle cancelling transitions is to use [3 Conditional transitions](#3-conditional-transitions). However if the logic is more than one liner you can cancel the event, hence the transition by returning `FiniteMachine::CANCELLED` constant from the callback scope. The two ways you can affect the event are

* `on_exit :state_name`
* `on_enter :event_name`

For example

```ruby
fm = FiniteMachine.define do
  initial :red

  events {
    event :ready, :red    => :yellow
    event :go,    :yellow => :green
    event :stop,  :green  => :red
  }
  callbacks {
    on_exit :red do |event| FiniteMachine::CANCELLED end
  }
end

fm.ready
fm.current  # => :red
```

## 5 Errors

By default, the **FiniteMachine** will throw an exception whenever the machine is in invalid state or fails to transition.

* `FiniteMachine::TransitionError`
* `FiniteMachine::InvalidStateError`
* `FiniteMachine::InvalidCallbackError`

You can attach specific error handler inside the `handlers` scope by passing the name of the error and actual callback to be executed when the error happens inside the `handle` method. The `handle` receives a list of exception class or exception class names, and an option `:with` with a name of the method or a Proc object to be called to handle the error. As an alternative, you can pass a block.

```ruby
fm = FiniteMachine.define do
  initial :green, event: :start

  events {
    event :slow,  :green  => :yellow
    event :stop,  :yellow => :red
  }

  handlers {
    handle FiniteMachine::InvalidStateError do |exception|
      # run some custom logging
      raise exception
    end

    handle FiniteMachine::TransitionError, with: proc { |exception| ... }
  }
end
```

### 5.1 Using target

You can pass an external context via `target` helper that will be the receiver for the handler. The handler method needs to take one argument that will be called with the exception.

```ruby
class Logger
  def log_error(exception)
    puts "Exception : #{exception.message}"
  end
end

fm = FiniteMachine.define do
  target logger

  initial :green

  events {
    event :slow, :green  => :yellow
    event :stop, :yellow => :red
  }

  handlers {
    handle 'InvalidStateError', with: :log_error
  }
end
```

## 6 Integration

Since **FiniteMachine** is an object in its own right it leaves integration with other systems up to you. In contrast to other Ruby libraries, it does not extend from models (i.e. ActiveRecord) to transform them into a state machine or require mixing into exisiting classes.

```ruby
class Car
  attr_accessor :reverse_lights

  def turn_reverse_lights_off
    @reverse_lights = false
  end

  def turn_reverse_lights_on
    @reverse_lights = true
  end

  def gears
    context = self
    @gears ||= FiniteMachine.define do
      initial :neutral

      target context

      events {
        event :start, :neutral => :one
        event :shift, :one => :two
        event :shift, :two => :one
        event :back,  [:neutral, :one] => :reverse
      }

      callbacks {
        on_enter :reverse do |event|
          turn_reverse_lights_on
        end

        on_exit :reverse do |event|
          turn_reverse_lights_off
        end

        on_transition do |event|
          puts "shifted from #{event.from} to #{event.to}"
        end
      }
    end
  end
end
```

### 6.1 ActiveRecord

In order to integrate **FiniteMachine** with ActiveRecord use the `target` helper to reference the current class and call ActiveRecord methods inside the callbacks to persist the state.

```ruby
class Account < ActiveRecord::Base
  validates :state, presence: true

  def initialize
    self.state = :unapproved
  end

  def manage
    context = self
    @manage ||= FiniteMachine.define do
      target context

      initial context.state

      events {
        event :enqueue, :unapproved => :pending
        event :authorize, :pending => :access
      }

      callbacks {
        on_enter_state do |event|
          state = event.to
          save
        end
      }
    end
  end
end

account = Account.new
account.state   # => :unapproved
account.manage.enqueue
account.state   # => :pending
account.manage.authorize
account.state   # => :access
```

## 7 Tips

Creating a standalone **FiniteMachine** brings a number of benefits, one of them being easier testing. This is especially true if the state machine is extremely complex itself. Ideally, you would test the machine in isolation and then integrate it with other objects or ORMs.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Copyright

Copyright (c) 2014 Piotr Murach. See LICENSE for further details.
