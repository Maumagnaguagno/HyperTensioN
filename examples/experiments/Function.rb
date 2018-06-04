module Function

  def function(f)
    @state[:function][f]
  end

  def assign(f, value)
    @state[:function][f] = value.to_f
    axioms_protected?
  end

  def increase(f, value)
    @state[:function][f] += value.to_f
    axioms_protected?
  end

  def decrease(f, value)
    @state[:function][f] -= value.to_f
    axioms_protected?
  end

  def scale_up(f, value)
    @state[:function][f] *= value.to_f
    axioms_protected?
  end

  def scale_down(f, value)
    @state[:function][f] /= value.to_f
    axioms_protected?
  end

  def axioms_protected?
    @state['protect_axiom'].all? {|i| send(*i)}
  end
end

module Continuous
  include Function

  def problem(state, *args)
    state[:event] = []
    state[:process] = []
    super(state, *args)
  end

  def function(f, time = nil)
    v = @state[:function][f]
    return v unless time
    time = time.to_f
    @state[:event].each {|type,g,value,start|
      if f == g and start <= time
        case type
        when 'increase' then v += value
        when 'decrease' then v -= value
        when 'scale_up' then v *= value
        when 'scale_down' then v /= value
        end
      end
    }
    @state[:process].each {|type,g,expression,start,finish|
      if f == g and start <= time
        value = send(*expression, (time > finish ? finish : time) - start)
        case type
        when 'increase' then v += value
        when 'decrease' then v -= value
        when 'scale_up' then v *= value
        when 'scale_down' then v /= value
        end
      end
    }
    v
  end

  def event(type, f, value, start)
    @state[:event] << [type, f, value.to_f, start.to_f]
  end

  def process(type, f, expression, start, finish)
    @state[:process] << [type, f, expression, start.to_f, finish.to_f]
  end
end