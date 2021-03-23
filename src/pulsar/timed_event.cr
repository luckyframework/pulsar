require "./base_event"

abstract class Pulsar::TimedEvent < Pulsar::BaseEvent
  macro inherited
    protected class_property subscribers = [] of self, Time::Span -> Nil
    # Used by `Pulsar::SpecHelper` to test for logged events
    class_property logged_events = [] of self
  end

  # Subscribe to events
  #
  # ```
  # MyEvent.subscribe do |event, duration|
  #   # Do something with the event and duration
  # end
  #
  # MyEvent.publish do
  #   # Do something
  # end
  # ```
  def self.subscribe(&block : self, Time::Span -> Nil)
    self.subscribers << block
  end

  # Publishes the event when the block finishes running.
  #
  # Similar to `Pulsar::Event#publish` but measures and publishes the time
  # it takes to run the block.
  #
  # ```
  # MyEvent.publish do
  #   # Run some code
  # end
  # ```
  #
  # The `publish` method returns the result of the block.
  #
  # ### Passing arguments to initialize
  #
  # If your event defines an `initialize` and requires arguments, you can
  # pass those arguments to `publish`.
  #
  # For example if you had the event:
  #
  # ```
  # class MyEvent < Pulsar::TimedEvent
  #   def initialize(custom_argument : String)
  #   end
  # end
  # ```
  #
  # You would pass the arguments to `publish` and they will be used to
  # initialize the event:
  #
  # ```
  # MyEvent.publish(custom_argument: "This is my custom event argument") do
  #   # ...run some code
  # end
  # ```
  def self.publish(*args_, **named_args_)
    # Name it args_ so if the initializer has an `args` argument `publish` will still work
    new(*args_, **named_args_).publish do
      yield
    end
  end

  protected def publish
    Pulsar.maybe_log_event(self)
    start = Time.monotonic
    result = yield
    duration = Time.monotonic - start

    self.class.subscribers.each do |s|
      s.call(self, duration)
    end

    result
  end
end
