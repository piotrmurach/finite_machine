# Change Log

## [v0.12.0] - unreleased

### Changed

### Fixed
* Fix memory leak - issue #42

## [v0.11.2] - 2015-12-30

### Added
* Add infering of state or event name based off hook type

### Changed
* Remove ThreadContext for global queue synchronization
* Change EventQueue to use Threadable module to sync access

### Fixed
* Fix bug with two state machines locking up on callback events due to race condition with help from @domokos

## [v0.11.1] - 2015-12-17

### Fixed
* Fix cancelling callbacks for halted transition by craiglittle

## [v0.11.0] - 2015-10-11

### Added
* Add UndefinedTransition to mark self transition(e.i. no transition found)
* Add StateDefinition for state query methods
* Add #trigger and #trigger! to StateMachine to allow manual firing of events and split between dangerous and non-dangerous versions of api.

### Changed
* Change ThreadContext to require per thread setup
* Change Transition to stop relying on global transitions
* Change EventChain to manage all internal transitions
* Change Subscribers to remove unnecessary parameter dependency
* Change StateMachine public interface to clarify available methods
* Change HookEvent to accept event name and from state
* Remove Event class as duplicate of Transition
* Remove unnecessary checks for StateMachine#can?

### Fixed
* Fix bug in Transition with current transition matching
* Fix bug in Observer with cancelling inside event callback

## [v0.10.2] - 2015-07-05

### Changed
* Change StateParser #parse method
* Change EventBuilder to EventDefinition and invert dependencies
* Change Event#call to #trigger
* Change Transition#call to #execute

### Fixed
* Fix to run 'on_after' callbacks even when event cancalled by @craiglittle
* Fix to cancel transition when no matching choice is found by @craiglittle

## [v0.10.1] - 2015-05-24

### Added
* Add ability to inherit state machine definitions
* Add Env class for holiding machine envionment references

### Changed
* Change DSL to delegate calls to machine instance
* Change ChoiceMerger to use machine directly

## [v0.10.0] - 2014-11-16

### Added
* Add #alias_target to allow renaming of target object by @reggieb
* Add :log_transitions option for easy transition debugging

### Changed
* Change TransitionEvent, AsyncCall to be immutable
* Increase test coverage to 99%

### Fixed
* Fix issue with async calls passing wrong arguments to conditionals

## [v0.9.2] - 2014-09-27

### Changed
* Removes use of class variable to share Sync by @reggieb

### Fixed
* Fix observer to differentiate between any state and any event
* [#23] Fix transition to correctly set :from and :to parameters for :any state
* [#25] Fix passing parameters to choice events with same named events
* Fix choice pseudostate to work with :any state

## [v0.9.1] - 2014-08-10

### Added
* Add TransitionBuilder to internally build transitions from states
* Add #current? to Transition to determine if matches from state
* Add #select_choice_transition to EventsChain to determine matching choice transition

### Fixed
* Fix #choice to allow for multiple from states
* Fix #choice to work with same named events

## [v0.9.0] 2014-08-03

### Added
* Add Definition class to allow to define standalone state machine
* Add #build method to HookEvent

### Changed
* Change initial helper to simply state name with options
* Change HookEvent to be immutable and extend comparison
* Change Event to be immutable and extend comparison
* Change finished? to terminated? and allow for multiple terminal states
* Change to require explicit context to call target methods
* Upgrade RSpec dependency and refactor specs

## [v0.8.1] - 2014-07-05

### Added
* Add EventsChain to handle internal events logic
* Add EventBuilder to handle events construction

## [v0.8.0] - 2014-06-22

### Added
* Add silent option for state machine events to allow turning on/off
  selectively callbacks
* Ensure that can? & cannot? take into account conditionl logic applied
  to transitions
* Add restore! method to allow to set the state directly without callbacks
* Add ability to do dynamic conditional branching using the choice DSL or
  grouped events with different outgoing transitions [solves #13 and #6 issue]

## [v0.7.1] - 2014-06-08

### Changed
* Change to relax callback name checks to allow for duplicate state and event names
* Change so that transition to initial state triggers callbacks

## [v0.7.0] - 2014-05-26

### Added
* Add Event to hold the logic for event specification
* Add string inspection to hooks
* Add check for callback name conflicts

### Changed
* Change Event to EventHook for callback events
* Change to allow for self-transition - fixes issue #9
* Change to detect attempt to overwrite already defined method - fixes issue #10
* Change to separate state and event callbacks. Introduced on_enter, on_before,
  once_on_enter, once_on_before new event callbacks.
* Change generic callbacks to default to any state for on_enter, on_transition,
  on_exit and any event for on_before and on_after
* Change to ensure proper callback lifecycle

### Fixed
* Fix issue #8 to preserve conditionals between event specifications
* Fix #respond_to on state machine to include observer
* Fix observer missing methods resolution

### [v0.6.1] - 2014-05-10

### Fixed
* Fix stdlib requirement

### [v0.6.0] - 2014-05-10

### Added
* Add StateParser to allow for grouping transition under same event name
* Add abilility to correctly extract :to state for Transition instance

### Changed
* Change Transition to store a map of transition for a given event

### Fixed
* Fix bug #6 with incorrect TransitionEvent payload information

## [v0.5.0] - 2014-04-28

### Added
* Add generic Listener interface
* Add ability to fire callbacks asynchronously
* Add initial state storage

### Changed
* Change to allow for machine to be constructed as plain object
* Allow for :initial, :terminal and :target to be machine parameters
* Change EventQueue to allow for subscription
* Increase test coverage to 98%
* Change to allow access to target inside machine dsl

## [v0.4.0] - 2014-04-13

### Added
* Add logger
* Add ability to cancel transitions inside callbacks
* Add ability to force transitions

### Changed
* Change initial state to stop firing event notification
* Increase test coverage to 97%

### Fixed
* Fix initial to accept any state object
* Fix proc conditions to accept aditional arguments

## [v0.3.0] - 2014-03-30

### Added
* Add ability to specify callbacks on machine instance
* Add once_on type of callback
* Add off method for removing callbacks
* Add async method to state_machine for asynchronous events firing
* Add state helpers fsm.green? to allow easily check current state

### Changed
* Change attr_threadsafe to accept default values
* Move development dependencies to Gemfile
* Increase test coverage to 95%

### Fixed
* Fix bug with event methods dynamic redefinition
* Fix observer respond_to
* Fix Callable to correctly forward arguments

## [v0.2.0] - 2014-03-01

### Added
* Add generic state and event listeners
* Add target to allow integration with external objects,
  and allow easy method lookup through callback context
* Add ability to specify custom handlers for error conditions
* Add methods synchronization for thread safety
* Add ability to define custom initial event
* Add hooks class for callbacks registration

### Changed
* Change to ensure correct transition object state
* Extend threadable accessors

### Fixed
* Fix bug - callback event object returns correct from state

[v0.11.2]: https://github.com/peter-murach/finite_machine/compare/v0.11.1...v0.11.2
[v0.11.1]: https://github.com/peter-murach/finite_machine/compare/v0.11.0...v0.11.1
[v0.11.0]: https://github.com/peter-murach/finite_machine/compare/v0.10.2...v0.11.0
[v0.10.2]: https://github.com/peter-murach/finite_machine/compare/v0.10.1...v0.10.2
[v0.10.1]: https://github.com/peter-murach/finite_machine/compare/v0.10.0...v0.10.1
[v0.10.0]: https://github.com/peter-murach/finite_machine/compare/v0.9.2...v0.10.0
[v0.9.2]: https://github.com/peter-murach/finite_machine/compare/v0.9.1...v0.9.2
[v0.9.1]: https://github.com/peter-murach/finite_machine/compare/v0.9.0...v0.9.1
[v0.9.0]: https://github.com/peter-murach/finite_machine/compare/v0.8.1...v0.9.0
[v0.8.1]: https://github.com/peter-murach/finite_machine/compare/v0.8.0...v0.8.1
[v0.8.0]: https://github.com/peter-murach/finite_machine/compare/v0.7.1...v0.8.0
[v0.7.1]: https://github.com/peter-murach/finite_machine/compare/v0.7.0...v0.7.1
[v0.7.0]: https://github.com/peter-murach/finite_machine/compare/v0.6.1...v0.7.0
[v0.6.1]: https://github.com/peter-murach/finite_machine/compare/v0.6.0...v0.6.1
[v0.6.0]: https://github.com/peter-murach/finite_machine/compare/v0.5.0...v0.6.0
[v0.5.0]: https://github.com/peter-murach/finite_machine/compare/v0.4.0...v0.5.0
[v0.4.0]: https://github.com/peter-murach/finite_machine/compare/v0.3.0...v0.4.0
[v0.3.0]: https://github.com/peter-murach/finite_machine/compare/v0.2.0...v0.3.0
[v0.2.0]: https://github.com/peter-murach/finite_machine/compare/v0.1.0...v0.2.0
