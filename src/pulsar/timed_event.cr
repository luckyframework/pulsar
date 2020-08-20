abstract class Pulsar::TimedEvent
  # When the event started
  getter :started_at

  macro inherited
    @started_at : Time = Time.utc
    protected class_property subscribers = [] of self, Time::Span -> Nil
  end

  # Subscribe to events
  #
  # ```crystal
  # MyEvent.subscribe do |event, duration|
  #   # Do something with the event and duration
  # end
  #
  # MyEvent.new.publish do
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
  # ```crystal
  # MyEvent.new.publish do
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
  # ```crystal
  # class MyEvent < Pulsar::TimedEvent
  #   def initialize(custom_argument : String)
  #   end
  # end
  # ```
  #
  # You would pass the arguments to `publish` and they will be used to
  # initialize the event:
  #
  # ```crystal
  # MyEvent.publish(custom_argument: "This is my custom event argument") do
  #   # ...run some code
  # end
  # ```
  def self.publish(*args, **named_args)
    new(*args, **named_args).publish do
      yield
    end
  end

  protected def publish
    start = Time.monotonic
    result = yield
    duration = Time.monotonic - start

    self.class.subscribers.each do |s|
      s.call(self, duration)
    end

    result
  end

  # Returns the name of the event.
  #
  # The event name is the name of the class. So an class of `MyShard::MyEvent` would
  # return `"MyShard::MyEvent"`.
  def name
    self.class.name
  end
end
