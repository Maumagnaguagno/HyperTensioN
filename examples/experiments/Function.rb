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

  def over_all_predicate(p, status, start, finish)
    pre, *terms = p
    v = @state[pre].include?(terms)
    status = status == 'true'
    start = start.to_f
    finish = finish.to_f
    t = 0
    @state[:event].each {|type,g,value,time|
      if p == g
        if t <= time and time < start
          t = start
          v = value
        elsif value != status and start <= time and time <= finish
          return false
        end
      end
    }
    v == status
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

    def x_less_than(y, time = nil)
      function(:x, time) < y
    end

    def happy(time = nil)
      at_time(['happy', 'you'], time)
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

    def test_instantaneous
      setup_initial_state
      assert_equal(0, function(:x))
      assert_equal(true, increase(:x, 5))
      assert_equal(5, function(:x))
      assert_equal(true, decrease(:x, 3))
      assert_equal(2, function(:x))
      assert_equal(true, scale_up(:x, 2))
      assert_equal(4, function(:x))
      assert_equal(true, scale_down(:x, 4))
      assert_equal(1, function(:x))
      assert_equal(true, assign(:x, 10))
      assert_equal(10, function(:x))
      @state['protect_axiom'] << ['x_less_than', 11]
      assert_equal(true, axioms_protected?)
      @state['protect_axiom'] << ['x_less_than', 10]
      assert_equal(false, axioms_protected?)
    end

    def test_event
      setup_initial_state
      assert_equal(true, event('increase', :x, 1, 1))
      assert_equal(0, function(:x))
      assert_equal(0, function(:x, 0.5))
      assert_equal(1, function(:x, 1))
      assert_equal(1, function(:x, 1.5))
      @state['protect_axiom'].push(['x_less_than', 11], ['x_less_than', 11, 1.5])
      assert_equal(true, axioms_protected?)
      @state['protect_axiom'] << ['x_less_than', 1, 1.5]
      assert_equal(false, axioms_protected?)
    end

    def test_process
      setup_initial_state
      assert_equal(true, process('increase', :x, :identity, 1, 5))
      assert_equal(0, function(:x))
      assert_equal(0, function(:x, 0.5))
      assert_equal(0, function(:x, 1))
      assert_equal(0.5, function(:x, 1.5))
      assert_equal(4, function(:x, 5))
      assert_equal(4, function(:x, 6))
      @state['protect_axiom'].push(['x_less_than', 11], ['x_less_than', 11, 6])
      assert_equal(true, axioms_protected?)
      @state['protect_axiom'] << ['x_less_than', 4, 6]
      assert_equal(false, axioms_protected?)
    end

    def test_at_time
      setup_initial_state
      pre = ['happy', 'you']
      assert_equal(true, modify(pre, 'false', 1))
      assert_equal(true, modify(pre, 'true', 5))
      assert_equal(true, at_time(pre))
      assert_equal(true, at_time(pre, 0.5))
      assert_equal(false, at_time(pre, 1))
      assert_equal(false, at_time(pre, 1.5))
      assert_equal(true, at_time(pre, 5))
      assert_equal(true, at_time(pre, 6))
      @state['protect_axiom'].push(['happy'], ['happy', 6])
      assert_equal(true, axioms_protected?)
      @state['protect_axiom'] << ['happy', 2]
      assert_equal(false, axioms_protected?)
    end

    def test_over_all_predicate
      setup_initial_state
      pre = ['happy', 'you']
      assert_equal(true, over_all_predicate(pre, 'true', 0, 1))
      assert_equal(false, over_all_predicate(pre, 'false', 0, 1))
      assert_equal(false, over_all_predicate(['happy', 'x'], 'true', 0, 1))
      assert_equal(true, over_all_predicate(['happy', 'x'], 'false', 0, 1))
      assert_equal(true, modify(pre, 'false', 0.5))
      assert_equal(false, over_all_predicate(pre, 'true', 0, 1))
      assert_equal(false, over_all_predicate(pre, 'false', 0, 1))
      assert_equal(false, over_all_predicate(pre, 'true', 0, 0.5))
      assert_equal(false, over_all_predicate(pre, 'false', 0, 0.5))
      assert_equal(false, over_all_predicate(pre, 'true', 0.5, 1))
      assert_equal(false, over_all_predicate(pre, 'false', 0.5, 1))
      assert_equal(true, over_all_predicate(pre, 'true', 0, 0.45))
      assert_equal(false, over_all_predicate(pre, 'false', 0, 0.45))
      assert_equal(false, over_all_predicate(pre, 'true', 0.55, 1))
      assert_equal(true, over_all_predicate(pre, 'false', 0.55, 1))
    end
  end
end