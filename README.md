# Pulsar

[![API Documentation Website](https://img.shields.io/website?down_color=red&down_message=Offline&label=API%20Documentation&up_message=Online&url=https%3A%2F%2Fluckyframework.github.io%2Fpulsar%2F)](https://luckyframework.github.io/pulsar)

Pulsar is a simple Crystal library for publishing and subscribing to events.
It also has timing information for metrics. So what does that mean in
practice?

You can define an event and any number of subscribers can subscribe to the
event and do whatever they need with it.

For example, in Lucky, we use Pulsar to create events for things like
requests being processed, queries being made, before and after pipes running.
Then we subscribe to these events to write to the logs. We also use this
internally to log debugging information in an upcoming UI called Breeze that
let's users debug development information.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     pulsar:
       github: luckyframework/pulsar
   ```

2. Run `shards install`

## How to use Pulsar

Let's say we're writing a library to charge a credit card and we may want to let
people run code whenever a charge is made. Here's how you can do that with Pulsar.

### Create and publish an event

```crystal
class PaymentProcessor::ChargeCardEvent < Pulsar::Event
  def initialize(@amount : Int32)
  end
end

class PaymentProcessor
  def charge_card(amount : Int32)
    # Run code to charge the card...

    # Then fire an event
    PaymentProcessor::ChargeCardEvent.publish(amount)
  end
end
```

### Subscribe to it and do whatever you want with it

Now you can subscribe to the event and do whatever you want with it. For example,
you might log that a charge was made, or you might send an email to the sales team.

```crystal
PaymentProcessor::ChargeCardEvent.subscribe do |event|
  puts "Charged: #{event.amount} at #{event.started_at}"
end
```

### Recording timing information

You can also time how long it takes to run an event by inheriting from
`Pulsar::TimedEvent`. You define them in the same way, but when you subscribe
you must also accept a second argument:

```crystal
class Database::QueryEvent < Pulsar::TimedEvent
end

Database::QueryEvent.subscribe do |event, duration|
  # Do something with the event and duration
end

Database::QueryEvent.publish do
  # Run a query, run some other code, etc.
end
```

### Add more information to the event

To add more information to the event you can use `initialize` like you would
with any other Crystal class.

For example, we can record the database query in the event from above

```crystal
class Database::QueryEvent < Pulsar::TimedEvent
  getter :query

  def initialize(@query : String)
  end
end

Database::QueryEvent.subscribe do |event, duration|
  puts event.query
end

Database::QueryEvent.publish(query: "SELECT * FROM users") do
  # Run a query, run some other code, etc.
end
```

## Testing Pulsar events

If you want to test that events are published you can use Pulsar's built-in test mode.

```crystal
# Typically in spec/spec_helper.cr

# Must come *after* `require "spec"`
Pulsar.enable_test_mode!
```

This will enable an in-memory log for published events and will set up a hook to
clear the events before each spec runs.

You can access events using `{MyEventClass}.logged_events`.

```crystal
# Create an event
class QueryEvent < Pulsar::TimedEvent
  def initialize(@query : String)
  end
end

def run_my_query(query)
  # Publish the event
  QueryEvent.publish(query: query) do
    # Run the query somehow
  end
end

it "publishes an event when a SQL query is executed" do
  run_my_query "SELECT * FROM users

  the_published_event = QueryEvent.logged_events.first
  the_published_event.query.should eq("SELECT * FROM users")
end
```

## `Pulsar.elapsed_text`

`Pulsar.elapsed_text` will return the time taken (`Time::Span`) as a human readable String.

```crystal
Database::QueryEvent.subscribe do |event, duration|
  puts Pulsar.elapsed_text(duration) # "2.3ms"
end
```

This method can be used with any `Time::Span`.

## Asynchronous Subscribers

Pulsar now supports asynchronous event subscribers that automatically run in a separate fiber:

```crystal
# Regular synchronous subscriber
MyEvent.subscribe do |event|
  # This runs synchronously and can block
end

# Asynchronous subscriber
MyEvent.subscribe_async do |event|
  # This automatically runs in a new fiber
  HTTP::Client.post("https://example.com/webhook", body: event.to_json)
end

# Also works with timed events
Database::QueryEvent.subscribe_async do |event, duration|
  # Won't block other subscribers
  send_metrics_to_monitoring_service(event.query, duration)
end
```

## Error Handling

Pulsar provides configurable error handling for subscribers:

```crystal
# Configure the error handling strategy
Pulsar::ErrorHandler.strategy = Pulsar::ErrorHandler::Strategy::Log # Default

# Available strategies:
# - Ignore: Silently ignore errors and continue
# - Log: Log errors and continue (default)
# - Raise: Stop processing and raise the error
# - Custom: Use a custom error handler

# Custom error handling
Pulsar::ErrorHandler.strategy = Pulsar::ErrorHandler::Strategy::Custom
Pulsar::ErrorHandler.custom_handler = ->(exception, event) {
  MyErrorReporter.report(exception, context: {event: event.name})
  nil
}
```

## Performance gotchas

Subscribers are notified synchronously in the same Fiber as the publisher.
This means that if you have a subscriber that takes a long time to run, it
will block anything else from running.

If you are doing some logging it is probably fine, but if you are doing
something more time-intensive or failure prone like making an HTTP request or
saving to the database you should use `subscribe_async` instead:

### Example of a problematic subscriber

```crystal
MyEvent.subscribe do |event|
  sleep(5)
end

MyEvent.publish

puts "I just took 5 seconds to print!"
```

### Solution: Use async subscribers

```crystal
MyEvent.subscribe_async do |event|
  # This automatically runs in a new Fiber
  sleep(5)
end

MyEvent.publish

puts "This will print right away!"
```

### Alternative solutions

You could also use a background job library like https://github.com/robacarp/mosquito.

Be aware that running things in a Fiber will lose the current Fiber's context. This is
important for logging since `Log.context` only works for the current Fiber.
So if you plan to log using the built-in Logger, you likely _do not_ want to
use async subscribers for logging. It is fast enough to just log synchronously.

## Contributing

1. Fork it (<https://github.com/luckyframework/pulsar/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [paulcsmith](https://github.com/paulcsmith) - creator and maintainer
