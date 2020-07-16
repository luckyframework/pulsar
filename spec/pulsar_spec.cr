require "./spec_helper"

class Pulsar::TestEvent < Pulsar::Event
end

describe Pulsar do
  describe "#name" do
    it "auto generates the name from the class" do
      Pulsar::TestEvent.new.name.should eq("Pulsar::TestEvent")
    end
  end

  it "allows subscribing and publishing events" do
    called = false
    Pulsar::TestEvent.subscribe do |event|
      called = true
      event.should be_a(Pulsar::TestEvent)
    end
    called.should be_false

    Pulsar::TestEvent.new.publish

    called.should be_true
  end
end
