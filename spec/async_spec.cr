require "./spec_helper"

class Pulsar::AsyncTestEvent < Pulsar::Event
end

class Pulsar::AsyncTestTimedEvent < Pulsar::TimedEvent
end

describe "Pulsar async subscribers" do
  after_each do
    Pulsar::AsyncTestEvent.clear_subscribers
    Pulsar::AsyncTestTimedEvent.clear_subscribers
  end

  describe "Event.subscribe_async" do
    it "runs subscribers asynchronously" do
      channel = Channel(Int32).new

      Pulsar::AsyncTestEvent.subscribe_async do |_event|
        sleep 10.milliseconds
        channel.send(1)
      end

      Pulsar::AsyncTestEvent.subscribe_async do |_event|
        sleep 10.milliseconds
        channel.send(2)
      end

      start_time = Time.monotonic
      Pulsar::AsyncTestEvent.publish
      publish_time = Time.monotonic - start_time

      # Publish should return immediately without waiting
      publish_time.should be < 0.005.seconds

      # Both async subscribers should complete
      results = [channel.receive, channel.receive].sort
      results.should eq([1, 2])
    end

    it "doesn't block synchronous subscribers" do
      sync_called = false
      async_channel = Channel(Nil).new

      Pulsar::AsyncTestEvent.subscribe do |_event|
        sync_called = true
      end

      Pulsar::AsyncTestEvent.subscribe_async do |_event|
        sleep 10.milliseconds
        async_channel.send(nil)
      end

      Pulsar::AsyncTestEvent.publish

      # Sync subscriber should have been called immediately
      sync_called.should be_true

      # Async subscriber should complete later
      async_channel.receive
    end
  end

  describe "TimedEvent.subscribe_async" do
    it "runs timed subscribers asynchronously" do
      channel = Channel(Float64).new

      Pulsar::AsyncTestTimedEvent.subscribe_async do |_event, duration|
        sleep 10.milliseconds
        channel.send(duration.total_milliseconds)
      end

      start_time = Time.monotonic
      Pulsar::AsyncTestTimedEvent.publish do
        sleep 2.milliseconds
      end
      publish_time = Time.monotonic - start_time

      # Should only wait for the block inside publish, not the async subscriber
      publish_time.should be < 0.01.seconds

      # Async subscriber should receive the duration
      duration_ms = channel.receive
      duration_ms.should be > 2.0
    end
  end

  describe "error handling with async subscribers" do
    it "handles errors in async subscribers based on strategy" do
      Pulsar::ErrorHandler.strategy = Pulsar::ErrorHandler::Strategy::Custom

      errors_channel = Channel(String).new

      Pulsar::ErrorHandler.custom_handler = ->(exception : Exception, event : Pulsar::BaseEvent) {
        errors_channel.send("#{event.name}: #{exception.message}")
        nil
      }

      Pulsar::AsyncTestEvent.subscribe_async do |_event|
        raise "Async error"
      end

      Pulsar::AsyncTestEvent.publish

      # Error should be handled in the spawned fiber
      error_msg = errors_channel.receive
      error_msg.should eq("Pulsar::AsyncTestEvent: Async error")
    end
  end
end
