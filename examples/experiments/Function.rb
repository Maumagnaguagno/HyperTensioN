module Function

  def problem(state, *args)
    function = state[:function] = {}
    state.delete('function')&.each {|f,v| function[f] = v.to_f}
    state['protect_axiom'] ||= []
    super
  end

  def function(f)
    @state[:function][f].to_s
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
    @state['protect_axiom'].all? {|i| __send__(*i)}
  end

  def function_effect
    (@state = @state.dup)[:function] = @state[:function].dup
  end

  def step(t, min = 0.0, max = Float::INFINITY, epsilon = 1.0)
    min.to_f.step(max.to_f, epsilon.to_f) {|i|
      t.replace(i.to_s)
      yield
    }
  end
end

module Continuous
  include Function

  def problem(state, *args)
    state[:event] = []
    state[:process] = []
    super
  end

  def function(f, time = nil, string = true)
    v = @state[:function][f]
    return string ? v.to_s : v unless time
    time = time.to_f
    ev = @state[:event]
    pr = @state[:process]
    ev_index = pr_index = 0
    while ev_index != ev.size or pr_index != pr.size
      if ev[ev_index] and (not pr[pr_index] or ev[ev_index][3] <= pr[pr_index][3])
        type, g, value, start = ev[ev_index]
        break if start > time
        if f == g
          case type
          when 'increase' then v += value
          when 'decrease' then v -= value
          when 'scale_up' then v *= value
          when 'scale_down' then v /= value
          when 'assign' then v = value
          end
        end
        ev_index += 1
      else
        type, g, expression, start, finish = pr[pr_index]
        break if start > time
        if f == g
          value = __send__(*expression, (time > finish ? finish : time) - start)
          case type
          when 'increase' then v += value
          when 'decrease' then v -= value
          when 'scale_up' then v *= value
          when 'scale_down' then v /= value
          end
        end
        pr_index += 1
      end
    end
    string ? v.to_s : v
  end

  def function_interval(f, start_time, finish_time, string = true, step = 1)
    v = @state[:function][f]
    ev = @state[:event]
    pr = @state[:process]
    start_time = start_time.to_f
    finish_time = finish_time.to_f
    ev_index = pr_index = 0
    while ev_index != ev.size or pr_index != pr.size
      if ev[ev_index] and (not pr[pr_index] or ev[ev_index][3] <= pr[pr_index][3])
        type, g, value, start = ev[ev_index]
        break if start > finish_time
        if f == g
          value *= finish_time - start
          case type
          when 'increase' then v += value
          when 'decrease' then v -= value
          when 'scale_up' then v *= value
          when 'scale_down' then v /= value
          when 'assign' then v = value
          end
        end
        ev_index += 1
      else
        type, g, expression, start, finish = pr[pr_index]
        break if start > finish_time
        if f == g
          (start > start_time ? start : start_time).step(finish_time > finish ? finish : finish_time, step) {|t|
            value = __send__(*expression, t - start)
            case type
            when 'increase' then v += value
            when 'decrease' then v -= value
            when 'scale_up' then v *= value
            when 'scale_down' then v /= value
            end
          }
          if finish_time > finish
            value *= finish_time - finish
            case type
            when 'increase' then v += value
            when 'decrease' then v -= value
            when 'scale_up' then v *= value
            when 'scale_down' then v /= value
            end
          end
        end
        pr_index += 1
      end
    end
    string ? v.to_s : v
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

  def modify(p, status, start)
    status = status == 'true'
    start = start.to_f
    insert_ordered(@state[:event].each {|type,g,value,time| return status == value if start == time and p == g}, [nil, p, status, start])
    axioms_protected_at_time?(start)
  end

  def event(type, f, value, start)
    (@state = @state.dup)[:event] = @state[:event].dup
    insert_ordered(@state[:event], [type, f, value.to_f, start.to_f])
    axioms_protected_at_time?(start)
  end

  def process(type, f, expression, start, finish)
    (@state = @state.dup)[:process] = @state[:process].dup
    insert_ordered(@state[:process], [type, f, expression, start.to_f, finish.to_f])
    axioms_protected_at_time?(finish)
  end

  def events(events)
    ev = (@state = @state.dup)[:event] = @state[:event].dup
    events.map {|type,f,value,start|
      insert_ordered(ev, [type, f, value.to_f, start.to_f])
      start
    }.uniq.all? {|i| axioms_protected_at_time?(i)}
  end

  def processes(processes)
    pr = (@state = @state.dup)[:process] = @state[:process].dup
    processes.map {|type,f,expression,start,finish|
      insert_ordered(pr, [type, f, expression, start.to_f, finish.to_f])
      finish
    }.uniq.all? {|i| axioms_protected_at_time?(i)}
  end

  def insert_ordered(array, n)
    value = n[3]
    array.insert(array.bsearch_index {|i| value < i[3]} || -1, n)
  end

  def axioms_protected_at_time?(time)
    @state['protect_axiom'].all? {|i| __send__(*i, time)}
  end
end

#-----------------------------------------------
# Main
#-----------------------------------------------
if $0 == __FILE__
  require 'test/unit'

  class Exogenous < Test::Unit::TestCase
    include Continuous

    def identity(i)
      i
    end

    def x_less_than(y, time = nil)
      function(:x, time, false) < y
    end

    def x_zero(time)
      function(:x, time, false) == 0
    end

    def happy(time = nil)
      at_time(['happy', 'you'], time)
    end

    def setup_initial_state
      @state = {
        :event => [],
        :process => [],
        :function => {:x => 0.0},
        'happy' => [['you']],
        'protect_axiom' => []
      }
    end

    def test_instantaneous
      setup_initial_state
      assert_equal('0.0', function(:x))
      assert_true(increase(:x, 5))
      assert_equal('5.0', function(:x))
      assert_true(decrease(:x, 3))
      assert_equal('2.0', function(:x))
      assert_true(scale_up(:x, 2))
      assert_equal('4.0', function(:x))
      assert_true(scale_down(:x, 4))
      assert_equal('1.0', function(:x))
      assert_true(assign(:x, 10))
      assert_equal('10.0', function(:x))
      @state['protect_axiom'] << ['x_less_than', 11]
      assert_true(axioms_protected?)
      @state['protect_axiom'] << ['x_less_than', 10]
      assert_false(axioms_protected?)
    end

    def test_event
      setup_initial_state
      assert_true(event('scale_up', :x, 2, 10))
      assert_true(event('increase', :x, 1, 1))
      assert_true(event('assign', :x, 100, 15))
      assert_equal('0.0', function(:x))
      assert_equal('0.0', function(:x, 0.5))
      assert_equal('1.0', function(:x, 1))
      assert_equal('1.0', function(:x, 1.5))
      assert_equal('5.0', function_interval(:x, 0, 6))
      @state['protect_axiom'].push(['x_less_than', 11], ['x_less_than', 11, 1.5])
      assert_true(axioms_protected?)
      @state['protect_axiom'] << ['x_less_than', 1, 1.5]
      assert_false(axioms_protected?)
      assert_equal('2.0', function(:x, 11))
      assert_equal('100.0', function(:x, 15))
    end

    def test_process
      setup_initial_state
      assert_true(process('increase', :x, :identity, 1, 5))
      assert_equal('0.0', function(:x))
      assert_equal('0.0', function(:x, 0.5))
      assert_equal('0.0', function(:x, 1))
      assert_equal('0.5', function(:x, 1.5))
      assert_equal('4.0', function(:x, 5))
      assert_equal('4.0', function(:x, 6))
      assert_equal('14.0', function_interval(:x, 0, 6))
      @state['protect_axiom'].push(['x_less_than', 11], ['x_less_than', 11, 4.5])
      assert_true(axioms_protected?)
      @state['protect_axiom'] << ['x_less_than', 4, 6]
      assert_false(axioms_protected?)
    end

    def test_simultaneous_processes
      setup_initial_state
      assert_true(process('increase', :x, :identity, 5, 15))
      assert_true(process('increase', :x, :identity, 10, 20))
      0.step(25, 0.5) {|i| assert_equal(i < 5 ? 0 : i < 10 ? i - 5 : i < 15 ? i * 2 - 15 : i < 20 ? i : 20, function(:x, i, false))}
    end

    def test_event_interference
      setup_initial_state
      @state['protect_axiom'] << ['x_zero']
      assert_false(event('increase', :x, 100, 0))
      assert_true(event('decrease', :x, 100, 0))
      setup_initial_state
      @state['protect_axiom'] << ['x_zero']
      assert_true(events([
        ['increase', :x, 100, 0],
        ['decrease', :x, 100, 0]
      ]))
      assert_equal(0, function(:x, 100, false))
    end

    def test_process_interference
      setup_initial_state
      @state['protect_axiom'] << ['x_zero']
      assert_false(process('increase', :x, :identity, 0, 100))
      assert_true(process('decrease', :x, :identity, 0, 100))
      setup_initial_state
      @state['protect_axiom'] << ['x_zero']
      assert_true(processes([
        ['increase', :x, :identity, 0, 100],
        ['decrease', :x, :identity, 0, 100]
      ]))
      assert_equal(0, function(:x, 100, false))
    end

    def test_at_time
      setup_initial_state
      pre = ['happy', 'you']
      assert_true(modify(pre, 'false', 1))
      assert_true(modify(pre, 'true', 5))
      assert_true(at_time(pre))
      assert_true(at_time(pre, 0.5))
      assert_false(at_time(pre, 1))
      assert_false(at_time(pre, 1.5))
      assert_true(at_time(pre, 5))
      assert_true(at_time(pre, 6))
      @state['protect_axiom'].push(['happy'], ['happy', 6])
      assert_true(axioms_protected?)
      @state['protect_axiom'] << ['happy', 2]
      assert_false(axioms_protected?)
    end

    def test_modify_consistency
      setup_initial_state
      pre = ['happy', 'you']
      assert_true(modify(pre, 'true', 1))
      assert_true(modify(pre, 'true', 1))
      assert_false(modify(pre, 'false', 1))
      assert_true(modify(pre, 'false', 2))
      assert_true(modify(pre, 'false', 2))
      assert_false(modify(pre, 'true', 2))
    end

    def test_over_all_predicate
      setup_initial_state
      pre = ['happy', 'you']
      assert_true(over_all_predicate(pre, 'true', 0, 1))
      assert_false(over_all_predicate(pre, 'false', 0, 1))
      assert_false(over_all_predicate(['happy', 'x'], 'true', 0, 1))
      assert_true(over_all_predicate(['happy', 'x'], 'false', 0, 1))
      assert_true(modify(pre, 'false', 0.5))
      assert_false(over_all_predicate(pre, 'true', 0, 1))
      assert_false(over_all_predicate(pre, 'false', 0, 1))
      assert_false(over_all_predicate(pre, 'true', 0, 0.5))
      assert_false(over_all_predicate(pre, 'false', 0, 0.5))
      assert_false(over_all_predicate(pre, 'true', 0.5, 1))
      assert_false(over_all_predicate(pre, 'false', 0.5, 1))
      assert_true(over_all_predicate(pre, 'true', 0, 0.45))
      assert_false(over_all_predicate(pre, 'false', 0, 0.45))
      assert_false(over_all_predicate(pre, 'true', 0.55, 1))
      assert_true(over_all_predicate(pre, 'false', 0.55, 1))
    end
  end
end