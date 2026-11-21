{% skip_file unless Fiber.has_constant?(:ExecutionContext) && Fiber::ExecutionContext.has_constant?(:Parallel) %}

require "./spec_helper"
require "wait_group"

private PARALLEL_WORKERS    =    8
private PARALLEL_ITERATIONS = 2000
private SUBSCRIPTIONS       =  200

abstract class Pulsar::BaseEvent
  def self.subscriber_count : Int32
    subscribers.size
  end
end

class Pulsar::ParallelEvent < Pulsar::Event
  getter number : Int32

  def initialize(@number : Int32)
  end
end

class Pulsar::ParallelTimedEvent < Pulsar::TimedEvent
end

class Pulsar::ParallelSubscribedEvent < Pulsar::Event
end

class Pulsar::ParallelSubscribedTimedEvent < Pulsar::TimedEvent
end

private def in_parallel(&block : Int32 ->)
  context = Fiber::ExecutionContext::Parallel.new("pulsar-spec", PARALLEL_WORKERS)
  errors = Channel(Exception).new(PARALLEL_WORKERS)
  group = WaitGroup.new(PARALLEL_WORKERS)

  PARALLEL_WORKERS.times do |worker|
    context.spawn do
      block.call(worker)
    rescue ex
      errors.send(ex)
    ensure
      group.done
    end
  end

  group.wait
  errors.close
  if error = errors.receive?
    raise error
  end
end

describe "Pulsar parallel access" do
  before_each do
    Pulsar::ParallelSubscribedEvent.clear_subscribers
    Pulsar::ParallelSubscribedTimedEvent.clear_subscribers
  end

  it "logs every event published from different threads" do
    in_parallel do |worker|
      PARALLEL_ITERATIONS.times do |i|
        Pulsar::ParallelEvent.publish(worker * PARALLEL_ITERATIONS + i)
        Pulsar::ParallelTimedEvent.publish { i }
      end
    end

    total = PARALLEL_WORKERS * PARALLEL_ITERATIONS
    Pulsar::ParallelEvent.logged_events.size.should eq(total)
    Pulsar::ParallelEvent.logged_events.map(&.number).sort!.should eq((0...total).to_a)
    Pulsar::ParallelTimedEvent.logged_events.size.should eq(total)
  end

  it "allows reading and clearing logged events while publishing" do
    in_parallel do |worker|
      PARALLEL_ITERATIONS.times do |i|
        case worker % 4
        when 0 then Pulsar::ParallelEvent.logged_events.each(&.number)
        when 1 then Pulsar.clear_logged_events if i % 100 == 0
        else        Pulsar::ParallelEvent.publish(i)
        end
      end
    end

    Pulsar.clear_logged_events
    Pulsar::ParallelEvent.logged_events.should be_empty
  end

  it "returns a copy of the logged events" do
    Pulsar::ParallelEvent.publish(1)

    Pulsar::ParallelEvent.logged_events.clear

    Pulsar::ParallelEvent.logged_events.size.should eq(1)
  end

  it "keeps every subscriber added while publishing" do
    in_parallel do |worker|
      if worker.even?
        SUBSCRIPTIONS.times do
          Pulsar::ParallelSubscribedEvent.subscribe { }
          Pulsar::ParallelSubscribedTimedEvent.subscribe { |_event, _duration| }
        end
      else
        PARALLEL_ITERATIONS.times do
          Pulsar::ParallelSubscribedEvent.publish
          Pulsar::ParallelSubscribedTimedEvent.publish { nil }
        end
      end
    end

    calls = Atomic(Int32).new(0)
    Pulsar::ParallelSubscribedEvent.subscribe { calls.add(1) }
    Pulsar::ParallelSubscribedTimedEvent.subscribe { |_event, _duration| calls.add(1) }
    Pulsar::ParallelSubscribedEvent.publish
    Pulsar::ParallelSubscribedTimedEvent.publish { nil }
    calls.get.should eq(2)

    expected = PARALLEL_WORKERS // 2 * SUBSCRIPTIONS + 1
    Pulsar::ParallelSubscribedEvent.subscriber_count.should eq(expected)
    Pulsar::ParallelSubscribedTimedEvent.subscriber_count.should eq(expected)
  end
end
