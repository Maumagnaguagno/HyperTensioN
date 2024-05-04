require 'test/unit'
require './extensions/Pullup'

class Logic_High < Test::Unit::TestCase

  def operators_o1(precond_pos = [], precond_not = [])
    [
      ['o1', ['?x'],
        # Preconditions
        precond_pos,
        precond_not,
        # Effects
        [['p1', '?x']],
        [['p2', '?x']]
      ]
    ]
  end

  def operators_o2(precond_pos = [], precond_not = [])
    [
      ['o2', ['?y'],
        # Preconditions
        precond_pos,
        precond_not,
        # Effects
        [['p4', '?y']],
        []
      ]
    ]
  end

  def methods_m1(precond_pos = [], precond_not = [], subtasks = [['o1', '?a']])
    [
      ['m1', ['?a'],
        ['case_0', [],
          # Preconditions
          precond_pos,
          precond_not,
          # Subtasks
          subtasks
        ]
      ]
    ]
  end

  def test_pullup_no_tasks
    Pullup.apply(
      operators = operators_o1,
      methods = methods_m1,
      predicates = {'p1' => true, 'p2' => true},
      state = {'p1' => [], 'p2' => []},
      tasks = [],
      [], []
    )
    assert_equal(operators_o1, operators)
    assert_equal(methods_m1, methods)
    assert_equal({'p1' => true, 'p2' => true}, predicates)
    assert_equal({'p1' => [], 'p2' => []}, state)
    assert_true(tasks.empty?)
  end

  def test_pullup_no_effect_with_operator_task
    Pullup.apply(
      operators = operators_o1,
      methods = methods_m1,
      predicates = {'p1' => true, 'p2' => true},
      state = {'p1' => [], 'p2' => []},
      tasks = [true, ['o1', 'a']],
      [], []
    )
    assert_equal(operators_o1, operators)
    assert_equal(methods_m1, methods)
    assert_equal({'p1' => true, 'p2' => true}, predicates)
    assert_equal({'p1' => [], 'p2' => []}, state)
    assert_equal([true, ['o1', 'a']], tasks)
  end

  def test_pullup_no_effect_with_method_task
    Pullup.apply(
      operators = operators_o1,
      methods = methods_m1,
      predicates = {'p1' => true, 'p2' => true},
      state = {'p1' => [], 'p2' => []},
      tasks = [true, ['m1', 'a']],
      [], []
    )
    assert_equal(operators_o1, operators)
    assert_equal(methods_m1, methods)
    assert_equal({'p1' => true, 'p2' => true}, predicates)
    assert_equal({'p1' => [], 'p2' => []}, state)
    assert_equal([true, ['m1', 'a']], tasks)
  end

  def test_pullup_impossible_precondition_with_operator_task
    Pullup.apply(
      operators = operators_o1,
      methods = methods_m1([['p3']]),
      predicates = {'p1' => true, 'p2' => true, 'p3' => false},
      state = {'p1' => [], 'p2' => []},
      tasks = [true, ['o1', 'a']],
      [], []
    )
    assert_equal(operators_o1, operators)
    assert_true(methods.empty?)
    assert_equal({'p1' => true, 'p2' => true, 'p3' => nil}, predicates)
    assert_equal({'p1' => [], 'p2' => []}, state)
    assert_equal([true, ['o1', 'a']], tasks)
  end

  def test_pullup_impossible_precondition_with_method_task
    e = assert_raises(RuntimeError) {
      Pullup.apply(
        operators_o1,
        methods_m1([['p3']]),
        predicates = {'p1' => true, 'p2' => true, 'p3' => false},
        state = {'p1' => [], 'p2' => []},
        tasks = [true, ['m1', 'a']],
        [], []
      )
    }
    assert_equal('Domain defines no decomposition for m1', e.message)
  end

  def test_pullup_single_operator_subtask_with_operator_task
    Pullup.apply(
      operators = operators_o1([['p1', 'a']], [['p1', 'b']]),
      methods = methods_m1,
      predicates = {'p1' => true, 'p2' => true},
      state = {'p1' => [], 'p2' => []},
      tasks = [true, ['o1', 'a']],
      [], []
    )
    assert_equal(operators_o1([['p1', 'a']], [['p1', 'b']]), operators)
    assert_equal(methods_m1([['p1', 'a']], [['p1', 'b']]), methods)
    assert_equal({'p1' => true, 'p2' => true}, predicates)
    assert_equal({'p1' => [], 'p2' => []}, state)
    assert_equal([true, ['o1', 'a']], tasks)
  end

def test_pullup_single_operator_subtask_with_method_task
    Pullup.apply(
      operators = operators_o1([['p1', 'a']], [['p1', 'b']]),
      methods = methods_m1,
      predicates = {'p1' => true, 'p2' => true},
      state = {'p1' => [], 'p2' => []},
      tasks = [true, ['m1', 'a']],
      [], []
    )
    assert_equal(operators_o1, operators)
    assert_equal(methods_m1([['p1', 'a']], [['p1', 'b']]), methods)
    assert_equal({'p1' => true, 'p2' => true}, predicates)
    assert_equal({'p1' => [], 'p2' => []}, state)
    assert_equal([true, ['m1', 'a']], tasks)
  end

  def test_pullup_operators_without_interference
    Pullup.apply(
      operators = operators_o1([['p1', 'a']], [['p1', 'b']]).concat(operators_o2([['p4', 'a']])),
      methods = methods_m1([], [], [['o1', '?a'], ['o2', '?a']]),
      predicates = {'p1' => true, 'p2' => true, 'p4' => true},
      state = {'p1' => [], 'p2' => [], 'p4' => []},
      tasks = [true, ['m1', 'a']],
      [], []
    )
    assert_equal(operators_o1.concat(operators_o2([['p4', 'a']])), operators)
    assert_equal(methods_m1([['p1', 'a'], ['p4', 'a']], [['p1', 'b']], [['o1', '?a'], ['o2', '?a']]), methods)
    assert_equal({'p1' => true, 'p2' => true, 'p4' => true}, predicates)
    assert_equal({'p1' => [], 'p2' => [], 'p4' => []}, state)
    assert_equal([true, ['m1', 'a']], tasks)
  end

  def test_pullup_operators_with_interference
    Pullup.apply(
      operators = operators_o1([['p1', 'a']], [['p1', 'b']]).concat(operators_o2([['p1', 'a']])),
      methods = methods_m1([], [], [['o1', '?a'], ['o2', '?a']]),
      predicates = {'p1' => true, 'p2' => true, 'p4' => true},
      state = {'p1' => [], 'p2' => [], 'p4' => []},
      tasks = [true, ['m1', 'a']],
      [], []
    )
    assert_equal(operators_o1.concat(operators_o2([['p1', 'a']])), operators)
    assert_equal(methods_m1([['p1', 'a']], [['p1', 'b']], [['o1', '?a'], ['o2', '?a']]), methods)
    assert_equal({'p1' => true, 'p2' => true, 'p4' => true}, predicates)
    assert_equal({'p1' => [], 'p2' => [], 'p4' => []}, state)
    assert_equal([true, ['m1', 'a']], tasks)
  end

  def test_pullup_effect_interference_on_repeated_subtask
    Pullup.apply(
      operators = [
        ['act', [],
          # Preconditions
          [['pre']],
          [],
          # Effects
          [],
          [['pre']]
        ]
      ],
      methods = [
        ['t_repeat', [],
          ['case_0', [],
            # Preconditions
            [],
            [],
            # Subtasks
            [['t_op'], ['t_op']]
          ]
        ],
        ['t_op', [],
          ['case_0', [],
            # Preconditions
            [],
            [],
            # Subtasks
            [['act']]
          ]
        ]
      ],
      predicates = {'pre' => true},
      state = {'pre' => [[]]},
      tasks = [true, ['t_repeat']],
      [], []
    )
    assert_equal([['act', [], [], [], [], [['pre']]]], operators)
    assert_equal([['t_repeat', [], ['case_0', [], [['pre']], [], [['t_op'], ['t_op']]]], ['t_op', [], ['case_0', [], [['pre']], [], [['act']]]]], methods)
    assert_equal({'pre' => true}, predicates)
    assert_equal({'pre' => [[]]}, state)
    assert_equal([true, ['t_repeat']], tasks)
  end
end