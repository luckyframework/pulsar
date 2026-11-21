require "./spec_helper"

class Pulsar::SpecEvent < Pulsar::Event
  getter :custom_arg

  def initialize(@custom_arg : String)
  end
end

class Pulsar::TimedSpecEvent < Pulsar::TimedEvent
end

class OutsideNamespaceEvent < Pulsar::Event
end

describe "Pulsar test mode" do
  describe "in memory event log" do
    it "stores events if enabled" do
      Pulsar::SpecEvent.publish(custom_arg: "Test")
      Pulsar::TimedSpecEvent.publish { :do_nothing }

      Pulsar::SpecEvent.logged_events.size.should eq(1)
      Pulsar::SpecEvent.logged_events.first.custom_arg.should eq("Test")
      Pulsar::TimedSpecEvent.logged_events.size.should eq(1)
    end

    it "stores no events if disabled" do
      Pulsar.test_mode_enabled = false

      Pulsar::SpecEvent.publish(custom_arg: "Test")
      Pulsar::TimedSpecEvent.publish { :do_nothing }

      Pulsar::SpecEvent.logged_events.size.should eq(0)
      Pulsar::TimedSpecEvent.logged_events.size.should eq(0)
    end
  end

  describe "Pulsar.clear_logged_events" do
    it "clears all logged events" do
      Pulsar::SpecEvent.publish(custom_arg: "Test")
      Pulsar::SpecEvent.logged_events.size.should eq(1)

      Pulsar.clear_logged_events
      Pulsar::SpecEvent.logged_events.size.should eq(0)
    end

    it "clears events defined outside of the Pulsar namespace" do
      OutsideNamespaceEvent.publish
      OutsideNamespaceEvent.logged_events.size.should eq(1)

      Pulsar.clear_logged_events
      OutsideNamespaceEvent.logged_events.size.should eq(0)
    end
  end
end
