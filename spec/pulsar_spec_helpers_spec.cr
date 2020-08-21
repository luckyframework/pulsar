require "./spec_helper"

class Pulsar::SpecEvent < Pulsar::Event
  getter :custom_arg

  def initialize(@custom_arg : String)
  end
end

describe "Pulsar test mode" do
  describe "in memory event log" do
    # TODO: Test TimedEvent
    it "stores events if enabled" do
      Pulsar::SpecEvent.publish(custom_arg: "Test")

      Pulsar::SpecEvent.logged_events.size.should eq(1)
      Pulsar::SpecEvent.logged_events.first.custom_arg.should eq("Test")
    end

    it "stores no events if disabled" do
      Pulsar.test_mode_enabled = false
      Pulsar::SpecEvent.publish(custom_arg: "Test")
      Pulsar::SpecEvent.logged_events.size.should eq(0)
    end
  end

  describe "Pulsar.clear_logged_events" do
    it "clears all logged events" do
      Pulsar::SpecEvent.publish(custom_arg: "Test")
      Pulsar::SpecEvent.logged_events.size.should eq(1)

      Pulsar.clear_logged_events
      Pulsar::SpecEvent.logged_events.size.should eq(0)
    end
  end
end
