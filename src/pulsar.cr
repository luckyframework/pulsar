require "./pulsar/*"

module Pulsar
  VERSION = "0.1.0"

  # Will return the time taken (`Time::Span`) as a human readable `String`.
  #
  # ```crystal
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
