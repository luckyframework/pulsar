abstract class Pulsar::Event
  # When the event started
  getter :started_at

  macro inherited
    @started_at : Time = Time.utc
    protected class_property subscribers = [] of self -> Nil
  end

  # Subscribe to events
  #
  # ```crystal
  # MyEvent.subscribe do |event|
  #   puts event.name # "MyEvent"
  # end
  #
  # MyEvent.new.publish # Will run the block above
  # ```
  def self.subscribe(&block : self -> Nil)
    self.subscribers << block
  end

  # Publishes the event to all subscribers.
  #
  # ```crystal
  # MyEvent.new.publish
  # ```
  def publish
    self.class.subscribers.each do |s|
      s.call(self)
    end
  end

  # Returns the name of the event.
  #
  # The event name is the name of the class. So an class of `MyShard::MyEvent` would
  # return `"MyShard::MyEvent"`.
  def name
    self.class.name
  end
end
