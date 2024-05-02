require 'test/unit'
require './extensions/Pullup'

class Logic_High < Test::Unit::TestCase

  def operators_o1(precond_pos = nil, precond_not = nil)
    [
      ['o1', ['?x'],
        # Preconditions
        [*precond_pos],
        [*precond_not],
        # Effects
        [['p1', '?x']],
        [['p2', '?x']]
      ]
    ]
  end

  def methods_m1(precond_pos = nil, precond_not = nil)
    [
      ['m1', ['?a'],
        ['case_0', [],
          # Preconditions
          [*precond_pos],
          [*precond_not],
          # Subtasks
          [['o1', '?a']]
        ]
      ]
    ]
  end

  def test_pullup_no_tasks
    operators = operators_o1
    methods = methods_m1
    Pullup.apply(operators, methods, predicates = {'p1' => true, 'p2' => true}, state = {'p1' => [], 'p2' => []}, tasks = [], [], [])
    assert_equal(operators_o1, operators)
    assert_equal(methods_m1, methods)
    assert_equal({'p1' => true, 'p2' => true}, predicates)
    assert_equal({'p1' => [], 'p2' => []}, state)
    assert_true(tasks.empty?)
  end

  def test_pullup_no_effect_with_operator_task
    operators = operators_o1
    methods = methods_m1
    Pullup.apply(operators, methods, predicates = {'p1' => true, 'p2' => true}, state = {'p1' => [], 'p2' => []}, tasks = [true, ['o1', 'a']], [], [])
    assert_equal(operators_o1, operators)
    assert_equal(methods_m1, methods)
    assert_equal({'p1' => true, 'p2' => true}, predicates)
    assert_equal({'p1' => [], 'p2' => []}, state)
    assert_equal([true, ['o1', 'a']], tasks)
  end

  def test_pullup_no_effect_with_method_task
    operators = operators_o1
    methods = methods_m1
    Pullup.apply(operators, methods, predicates = {'p1' => true, 'p2' => true}, state = {'p1' => [], 'p2' => []}, tasks = [true, ['m1', 'a']], [], [])
    assert_equal(operators_o1, operators)
    assert_equal(methods_m1, methods)
    assert_equal({'p1' => true, 'p2' => true}, predicates)
    assert_equal({'p1' => [], 'p2' => []}, state)
    assert_equal([true, ['m1', 'a']], tasks)
  end

  def test_pullup_impossible_precondition_with_operator_task
    operators = operators_o1
    methods = methods_m1([['p3']])
    Pullup.apply(operators, methods, predicates = {'p1' => true, 'p2' => true, 'p3' => false}, state = {'p1' => [], 'p2' => []}, tasks = [true, ['o1', 'a']], [], [])
    assert_equal(operators_o1, operators)
    assert_true(methods.empty?)
    assert_equal({'p1' => true, 'p2' => true, 'p3' => nil}, predicates)
    assert_equal({'p1' => [], 'p2' => []}, state)
    assert_equal([true, ['o1', 'a']], tasks)
  end

  def test_pullup_impossible_precondition_with_method_task
    operators = operators_o1
    methods = methods_m1([['p3']])
    e = assert_raises(RuntimeError) {Pullup.apply(operators, methods, predicates = {'p1' => true, 'p2' => true, 'p3' => false}, state = {'p1' => [], 'p2' => []}, tasks = [true, ['m1', 'a']], [], [])}
    assert_equal('Domain defines no decomposition for m1', e.message)
  end

  def test_pullup_single_operator_subtask_with_operator_task
    operators = operators_o1([['p1', 'a']], [['p1', 'b']])
    methods = methods_m1
    Pullup.apply(operators, methods, predicates = {'p1' => true, 'p2' => true}, state = {'p1' => [], 'p2' => []}, tasks = [true, ['o1', 'a']], [], [])
    assert_equal(operators_o1([['p1', 'a']], [['p1', 'b']]), operators)
    assert_equal(methods_m1([['p1', 'a']], [['p1', 'b']]), methods)
    assert_equal({'p1' => true, 'p2' => true}, predicates)
    assert_equal({'p1' => [], 'p2' => []}, state)
    assert_equal([true, ['o1', 'a']], tasks)
  end

def test_pullup_single_operator_subtask_with_method_task
    operators = operators_o1([['p1', 'a']], [['p1', 'b']])
    methods = methods_m1
    Pullup.apply(operators, methods, predicates = {'p1' => true, 'p2' => true}, state = {'p1' => [], 'p2' => []}, tasks = [true, ['m1', 'a']], [], [])
    assert_equal(operators_o1, operators)
    assert_equal(methods_m1([['p1', 'a']], [['p1', 'b']]), methods)
    assert_equal({'p1' => true, 'p2' => true}, predicates)
    assert_equal({'p1' => [], 'p2' => []}, state)
    assert_equal([true, ['m1', 'a']], tasks)
  end
end