abstract class Pulsar::Event
  getter :started_at

  macro inherited
    @started_at : Time = Time.utc
    class_property subscribers = [] of self -> Nil
  end

  def self.subscribe(proc)
    self.subscribers << proc
  end

  def self.subscribe(&block : self -> Nil)
    self.subscribers << block
  end

  def publish
    self.class.subscribers.each do |s|
      s.call(self)
    end
  end

  def name
    self.class.name
  end
end
