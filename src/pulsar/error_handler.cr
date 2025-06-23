module Pulsar
  # Configuration for handling errors in event subscribers
  class ErrorHandler
    enum Strategy
      # Ignore the error and continue to next subscriber
      Ignore
      # Log the error and continue to next subscriber (default)
      Log
      # Stop processing and raise the error
      Raise
      # Call a custom handler
      Custom
    end

    class_property strategy : Strategy = Strategy::Log
    class_property custom_handler : (Exception, Pulsar::BaseEvent) -> Nil = ->(exception : Exception, event : Pulsar::BaseEvent) { }

    # Handle an error from a subscriber
    def self.handle(exception : Exception, event : Pulsar::BaseEvent)
      case strategy
      when .ignore?
        # Do nothing
      when .log?
        Log.error(exception: exception) { "Error in subscriber for #{event.name}" }
      when .raise?
        raise exception
      when .custom?
        custom_handler.call(exception, event)
      end
    end
  end
end
