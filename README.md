# Pulsar

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

## Example

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
    PaymentProcessor::ChargeCardEvent.new(amount).publish
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

Database::QueryEvent.new.publish do
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

Database::QueryEvent.new(query: "SELECT * FROM users").publish do
  # Run a query, run some other code, etc.
end
```

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     pulsar:
       github: luckyframework/pulsar
   ```

2. Run `shards install`

## Contributing

1. Fork it (<https://github.com/luckyframework/pulsar/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [paulcsmith](https://github.com/paulcsmith) - creator and maintainer
