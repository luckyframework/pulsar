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
  def publish
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
