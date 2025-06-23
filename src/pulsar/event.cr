require "./base_event"

abstract class Pulsar::Event < Pulsar::BaseEvent
  macro inherited
    protected class_property subscribers = [] of self -> Nil
    # Used by `Pulsar::SpecHelper` to test for logged events
    class_property logged_events = [] of self
  end

  # Subscribe to events
  #
  # ```
  # MyEvent.subscribe do |event|
  #   puts event.name # "MyEvent"
  # end
  #
  # MyEvent.publish # Will run the block above
  # ```
  def self.subscribe(&block : self -> Nil)
    self.subscribers << block
  end

  # Subscribe to events with async execution
  #
  # The subscriber will be executed in a new fiber, preventing it from
  # blocking other subscribers or the main execution flow.
  #
  # ```
  # MyEvent.subscribe_async do |event|
  #   # This runs in a separate fiber
  #   HTTP::Client.post("https://example.com/webhook", body: event.to_json)
  # end
  # ```
  def self.subscribe_async(&block : self -> Nil)
    subscribe do |event|
      spawn do
        begin
          block.call(event)
        rescue exception
          Pulsar::ErrorHandler.handle(exception, event)
        end
      end
    end
  end

  # Publishes the event to all subscribers.
  #
  # ```
  # MyEvent.publish
  # ```
  #
  # ### Passing arguments to initialize
  #
  # If your event defines an `initialize` and requires arguments, you can
  # pass those arguments to `publish`.
  #
  # For example if you had the event:
  #
  # ```
  # class MyEvent < Pulsar::Event
  #   def initialize(custom_argument : String)
  #   end
  # end
  # ```
  #
  # You would pass the arguments to `publish` and they will be used to
  # initialize the event:
  #
  # ```
  # MyEvent.publish(custom_argument: "This is my custom event argument")
  # ```
  def self.publish(*args_, **named_args_)
    # Name it args_ so if the initializer has an `args` argument `publish` will still work
    new(*args_, **named_args_).publish
  end

  protected def publish
    Pulsar.maybe_log_event(self)

    self.class.subscribers.each do |subscriber|
      begin
        subscriber.call(self)
      rescue exception
        Pulsar::ErrorHandler.handle(exception, self)
      end
    end
  end
end
