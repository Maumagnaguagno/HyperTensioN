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

  def function(f, time = -1)
    v = super(f)
    time = time.to_f
    @state[:continuous].each {|type,g,expression,start,finish|
      if f == g and start <= time
        case type
        when 'increase' then v += expression.call((time > finish ? finish : time) - start)
        when 'decrease' then v -= expression.call((time > finish ? finish : time) - start)
        end
      end
    }
    v
  end

  def activate(type, f, expression, start, finish)
    @state[:continuous] << [type, f, expression, start.to_f, finish.to_f]
  end
end