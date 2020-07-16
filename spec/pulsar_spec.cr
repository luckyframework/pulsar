require "./spec_helper"

class Pulsar::TestEvent < Pulsar::Event
end

class Pulsar::TestTimedEvent < Pulsar::TimedEvent
end

describe Pulsar do
  describe "#name" do
    it "auto generates the name from the class" do
      Pulsar::TestEvent.new.name.should eq("Pulsar::TestEvent")
      Pulsar::TestTimedEvent.new.name.should eq("Pulsar::TestTimedEvent")
    end
  end

  it "allows subscribing and publishing events" do
    called = false
    Pulsar::TestEvent.subscribe do |event|
      called = true
      event.started_at.should be_a(Time)
      event.should be_a(Pulsar::TestEvent)
    end

    Pulsar::TestEvent.new.publish

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

    duration = Pulsar::TestTimedEvent.new.publish do
      # Nothing
    end

    duration.should be_a(Time::Span)
    called.should be_true
  end
end
