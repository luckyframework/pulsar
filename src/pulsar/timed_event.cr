abstract class Pulsar::TimedEvent
  getter :started_at

  macro inherited
    @started_at : Time = Time.utc
    class_property subscribers = [] of self, Time::Span -> Nil
  end

  def self.subscribe(proc)
    self.subscribers << proc
  end

  def self.subscribe(&block : self, Time::Span -> Nil)
    self.subscribers << block
  end

  def instrument : Time::Span
    duration = Time.measure do
      yield
    end

    self.class.subscribers.each do |s|
      s.call(self, duration)
    end

    duration
  end

  def name
    self.class.name
  end
end
