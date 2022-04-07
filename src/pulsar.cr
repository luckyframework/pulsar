require "./pulsar/*"

module Pulsar
  VERSION     = "0.2.3"
  EVENT_TYPES = [] of Pulsar::Event.class | Pulsar::TimedEvent.class
  class_property? test_mode_enabled : Bool = false

  # Enable test mode to log published events
  #
  # This will enable an in memory log of events that gets cleared before each
  # spec is run. You can access an Event's log using the `logged_events` class
  # method
  #
  # ```
  # MyEvent.publish
  #
  # MyEvent.logged_events.size.should eq(1)
  # MyEvent.logged_events.first # Returns the event that was published
  # ```
  def self.enable_test_mode!
    Pulsar.test_mode_enabled = true
    Spec.before_each do
      # Re-enable on every spec run so it can be disabled for some specs and will
      # automatically be re-enabled on the next spec.
      Pulsar.test_mode_enabled = true
      Pulsar.clear_logged_events
    end
  end

  # :nodoc:
  # Used internally to clear logged events in test mode
  def self.clear_logged_events
    Pulsar::EVENT_TYPES.each do |event_type|
      event_type.logged_events.clear
    end
  end

  # :nodoc:
  def self.maybe_log_event(event : Pulsar::Event | Pulsar::TimedEvent)
    if Pulsar.test_mode_enabled?
      event.class.logged_events.push(event)
    end
  end

  # Will return the time taken (`Time::Span`) as a human readable `String`.
  #
  # ```
  # Database::QueryEvent.subscribe do |event, duration|
  #   puts Pulsar.elaspted_text(duration) # "2.3ms"
  # end
  # ```
  #
  # This method can be used with any `Time::Span`.
  def self.elapsed_text(elapsed : Time::Span) : String
    minutes = elapsed.total_minutes
    return "#{minutes.round(2)}m" if minutes >= 1

    seconds = elapsed.total_seconds
    return "#{seconds.round(2)}s" if seconds >= 1

    millis = elapsed.total_milliseconds
    return "#{millis.round(2)}ms" if millis >= 1

    "#{(millis * 1000).round(2)}µs"
  end
end
