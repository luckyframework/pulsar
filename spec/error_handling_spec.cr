require "./spec_helper"

class Pulsar::ErrorTestEvent < Pulsar::Event
end

class Pulsar::ErrorTestTimedEvent < Pulsar::TimedEvent
end

describe "Pulsar error handling" do
  after_each do
    Pulsar::ErrorHandler.strategy = Pulsar::ErrorHandler::Strategy::Log
    Pulsar::ErrorTestEvent.clear_subscribers
    Pulsar::ErrorTestTimedEvent.clear_subscribers
  end

  describe "with ignore strategy" do
    it "ignores errors and continues to next subscriber" do
      Pulsar::ErrorHandler.strategy = Pulsar::ErrorHandler::Strategy::Ignore

      calls = [] of Int32

      Pulsar::ErrorTestEvent.subscribe { calls << 1 }
      Pulsar::ErrorTestEvent.subscribe { raise "Test error" }
      Pulsar::ErrorTestEvent.subscribe { calls << 3 }

      Pulsar::ErrorTestEvent.publish

      calls.should eq([1, 3])
    end
  end

  describe "with raise strategy" do
    it "raises the error and stops processing" do
      Pulsar::ErrorHandler.strategy = Pulsar::ErrorHandler::Strategy::Raise

      calls = [] of Int32

      Pulsar::ErrorTestEvent.subscribe { calls << 1 }
      Pulsar::ErrorTestEvent.subscribe { raise "Test error" }
      Pulsar::ErrorTestEvent.subscribe { calls << 3 }

      expect_raises(Exception, "Test error") do
        Pulsar::ErrorTestEvent.publish
      end

      calls.should eq([1])
    end
  end

  describe "with custom strategy" do
    it "calls the custom handler" do
      Pulsar::ErrorHandler.strategy = Pulsar::ErrorHandler::Strategy::Custom

      handled_errors = [] of String

      Pulsar::ErrorHandler.custom_handler = ->(exception : Exception, event : Pulsar::BaseEvent) {
        handled_errors << "#{event.name}: #{exception.message}"
        nil
      }

      Pulsar::ErrorTestEvent.subscribe { raise "Custom error" }
      Pulsar::ErrorTestEvent.publish

      handled_errors.should eq(["Pulsar::ErrorTestEvent: Custom error"])
    end
  end

  describe "with timed events" do
    it "handles errors in timed event subscribers" do
      Pulsar::ErrorHandler.strategy = Pulsar::ErrorHandler::Strategy::Ignore

      calls = [] of Int32

      Pulsar::ErrorTestTimedEvent.subscribe { |_, _| calls << 1 }
      Pulsar::ErrorTestTimedEvent.subscribe { |_, _| raise "Timed error" }
      Pulsar::ErrorTestTimedEvent.subscribe { |_, _| calls << 3 }

      result = Pulsar::ErrorTestTimedEvent.publish { :success }

      calls.should eq([1, 3])
      result.should eq(:success)
    end
  end
end
