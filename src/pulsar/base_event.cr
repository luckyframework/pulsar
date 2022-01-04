abstract class Pulsar::BaseEvent
  macro inherited
    # When the event started
    getter started_at : Time = Time.utc
    \{% if !@type.abstract? %}
      Pulsar::EVENT_TYPES << self
    \{% end %}
  end

  # Returns the name of the event.
  #
  # The event name is the name of the class. So an class of `MyShard::MyEvent` would
  # return `"MyShard::MyEvent"`.
  def name
    self.class.name
  end

  # Clears any existing subscribers
  def self.clear_subscribers
    subscribers.clear
  end
end
