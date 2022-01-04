require "./spec_helper"

class Pulsar::TestEvent < Pulsar::Event
end

class Pulsar::TestTimedEvent < Pulsar::TimedEvent
end

class Pulsar::EventWithInit < Pulsar::Event
  def initialize(@something : String)
  end
end

describe Pulsar do
  describe ".elapsed_text" do
    it "formats time spans" do
      Pulsar.elapsed_text(2.minutes).should eq("2.0m")
      Pulsar.elapsed_text(59.seconds).should eq("59.0s")
      Pulsar.elapsed_text(999.milliseconds).should eq("999.0ms")
      Pulsar.elapsed_text(999.microseconds).should eq("999.0µs")
    end
  end

  describe "#name" do
    it "auto generates the name from the class" do
      Pulsar::TestEvent.new.name.should eq("Pulsar::TestEvent")
      Pulsar::TestTimedEvent.new.name.should eq("Pulsar::TestTimedEvent")
    end
  end

  describe "Pulsar::EVENT_TYPES" do
    it "include Pulsar::Events and TimedEvents" do
      Pulsar::EVENT_TYPES.should contain(Pulsar::TestEvent)
      Pulsar::EVENT_TYPES.should contain(Pulsar::TestTimedEvent)
    end
  end

  it "allows subscribing and publishing events" do
    called = false
    Pulsar::TestEvent.subscribe do |event|
      called = true
      event.started_at.should be_a(Time)
      event.should be_a(Pulsar::TestEvent)
    end

    Pulsar::TestEvent.publish

    called.should be_true
  end

  it "allows publishing with custom args" do
    called = false
    Pulsar::EventWithInit.subscribe do |_event|
      called = true
    end

    Pulsar::EventWithInit.publish(something: "foo")

    called.should be_true
  end

  it "allows instrumenting an event to record timing information" do
    called = false
    Pulsar::TestTimedEvent.subscribe do |event, duration|
      called = true
      event.started_at.should be_a(Time)
      duration.should be_a(Time::Span)
      event.should be_a(Pulsar::TestTimedEvent)
    end

    result = Pulsar::TestTimedEvent.publish do
      :return_me
    end

    result.should eq(:return_me)
    called.should be_true
  end

  it "allows clearing subscribers" do
    called = false
    Pulsar::TestEvent.subscribe do
      called = true
    end

    Pulsar::TestEvent.clear_subscribers
    Pulsar::TestEvent.publish

    called.should be_false
  end
end
