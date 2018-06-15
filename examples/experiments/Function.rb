module Function

  def problem(state, *args)
    state['protect_axiom'] ||= []
    super(state, *args)
  end

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

  def at_time(p, time = nil)
    pre, *terms = p
    v = @state[pre].include?(terms)
    return v unless time
    time = time.to_f
    t = 0
    @state[:event].each {|type,g,value,start|
      if p == g and t <= start and start <= time
        t = start
        v = value
      end
    }
    v
  end

  def modify(p, value, start)
    @state[:event] << [nil, p, value == 'true', start.to_f]
    axioms_protected?
  end

  def event(type, f, value, start)
    @state[:event] << [type, f, value.to_f, start.to_f]
    axioms_protected?
  end

  def process(type, f, expression, start, finish)
    @state[:process] << [type, f, expression, start.to_f, finish.to_f]
    axioms_protected?
  end
end

#-----------------------------------------------
# Main
#-----------------------------------------------
if $0 == __FILE__
  require 'test/unit'
  require_relative '../../Hypertension'

  class Exogenous < Test::Unit::TestCase
    include Continuous, Hypertension

    def identity(i)
      i
    end

    def setup_initial_state
      @state = {
        :event => [],
        :process => [],
        :function => {:x => 0},
        'happy' => [['you']],
        'protect_axiom' => []
      }
    end

    def test_event
      setup_initial_state
      event('increase', :x, 1, 1)
      assert_equal(0, function(:x))
      assert_equal(0, function(:x, 0.5))
      assert_equal(1, function(:x, 1))
      assert_equal(1, function(:x, 1.5))
    end

    def test_process
      setup_initial_state
      process('increase', :x, :identity, 1, 5)
      assert_equal(0, function(:x))
      assert_equal(0, function(:x, 0.5))
      assert_equal(0, function(:x, 1))
      assert_equal(0.5, function(:x, 1.5))
      assert_equal(4, function(:x, 5))
      assert_equal(4, function(:x, 6))
    end

    def test_at_time
      setup_initial_state
      pre = ['happy', 'you']
      modify(pre, 'false', 1)
      modify(pre, 'true', 5)
      assert_equal(true, at_time(pre))
      assert_equal(true, at_time(pre, 0.5))
      assert_equal(false, at_time(pre, 1))
      assert_equal(false, at_time(pre, 1.5))
      assert_equal(true, at_time(pre, 5))
      assert_equal(true, at_time(pre, 6))
    end
  end
end