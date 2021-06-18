require './tests/hypest'

class Paisley < Test::Unit::TestCase

  SWAP_PREDICATES = {
    'agent' => false,
    'p' => false,
    'p2' => false,
    'adjacent' => false,
    'at' => true,
    'bridge' => true,
    'empty' => true,
    'observed' => true
  }

  def swap_operator(name, parameters, constraint_terms = parameters)
    [name, ['?ag', '?b', *parameters],
      # Preconditions
      [
        ['agent', '?ag'], ['p'], ['p2', '?b'], ['adjacent' , *constraint_terms],
        ['bridge', '?from', '?b', '?to'], ['at', '?ag', '?from'], ['empty', '?to']
      ],
      [],
      # Effects
      [['at', '?ag', '?to'], ['empty', '?from']],
      [['at', '?ag', '?from'], ['empty', '?to']]
    ]
  end

  def swap_methods(names, parameters, precond_pos, free_variables2 = parameters.sort.push('?ag', '?b'))
    precond_pos2 = precond_pos.map {|pre| pre.map {|i| i == '?current' ? '?intermediate' : i == '?intermediate' ? '?current' : i}}.unshift(['empty', '?current'])
    base_precond1 = precond_pos.map {|pre| pre.map {|i| i == '?current' ? '?from' : i == '?intermediate' ? '?to' : i}} << ['empty', '?from']
    base_precond2 = precond_pos.map {|pre| pre.map {|i| i == '?current' ? '?from' : i == '?intermediate' ? '?to' : i}} << ['at', '?ag', '?to']
    precond_pos.unshift(['at', '?ag', '?current'])
    methods = [
      ['swap_at_until_at', ['?ag', '?to'],
        ['base', [], [['at', '?ag', '?to']], [], []],
      ],
      ['swap_at_until_empty', ['?ag', '?to'],
        ['base', base_precond1.flatten(1).grep(/^\?[^t]/).uniq!, base_precond1, [], []]
      ],
      ['swap_empty_until_at', ['?from'],
        ['base', base_precond2.flatten(1).grep(/^\?[^f]/).uniq!, base_precond2, [], []],
      ],
      ['swap_empty_until_empty', ['?from'],
        ['base', [], [['empty', '?from']], [], []]
      ]
    ]
    free_variables1 = parameters.sort << '?b'
    names.each {|name|
      methods[0] << ["using_#{name}", free_variables1,
        # Preconditions
        precond_pos,
        [['at', '?ag', '?to'], ['visited_at', '?ag', '?intermediate']],
        # Subtasks
        [
          [name, '?ag', '?b', *parameters],
          ['invisible_visit_at', '?ag', '?current'],
          ['swap_at_until_at', '?ag', '?to'],
          ['invisible_unvisit_at', '?ag', '?current']
        ]
      ]
      methods[1] << ["using_#{name}", free_variables1,
        # Preconditions
        precond_pos,
        [['at', '?ag', '?to'], ['visited_at', '?ag', '?intermediate']],
        # Subtasks
        [
          [name, '?ag', '?b', *parameters],
          ['invisible_visit_at', '?ag', '?current'],
          ['swap_at_until_empty', '?ag', '?to'],
          ['invisible_unvisit_at', '?ag', '?current']
        ]
      ]
      methods[2] << ["using_#{name}", free_variables2,
        # Preconditions
        precond_pos2,
        [['empty', '?from'], ['visited_empty', '?intermediate']],
        # Subtasks
        [
          [name, '?ag', '?b', *parameters.reverse],
          ['invisible_visit_empty', '?current'],
          ['swap_empty_until_at', '?from'],
          ['invisible_unvisit_empty', '?current']
        ]
      ]
      methods[3] << ["using_#{name}", free_variables2,
        # Preconditions
        precond_pos2,
        [['empty', '?from'], ['visited_empty', '?intermediate']],
        # Subtasks
        [
          [name, '?ag', '?b', *parameters.reverse],
          ['invisible_visit_empty', '?current'],
          ['swap_empty_until_empty', '?from'],
          ['invisible_unvisit_empty', '?current']
        ]
      ]
    }
    methods
  end

  def test_swap_flexible_parameters
    # Based on planks domain
    Patterns.apply([swap_operator('cross', ['?from', '?to'])], methods = [], SWAP_PREDICATES, [], tasks = [], [], [])
    assert_equal(swap_methods(['cross'], ['?current', '?intermediate'], [['adjacent', '?current', '?intermediate']]), methods)
    assert_equal([false], tasks)
    Patterns.apply([swap_operator('cross', ['?from', '?to'], ['?to', '?from'])], methods.clear, SWAP_PREDICATES, [], tasks.clear, [], [])
    assert_equal(swap_methods(['cross'], ['?current', '?intermediate'], [['adjacent', '?intermediate', '?current']]), methods)
    assert_equal([false], tasks)
    Patterns.apply([swap_operator('cross', ['?to', '?from'], ['?from', '?to'])], methods.clear, SWAP_PREDICATES, [], tasks.clear, [], [])
    assert_equal(swap_methods(['cross'], ['?intermediate', '?current'], [['adjacent', '?current', '?intermediate']]), methods)
    assert_equal([false], tasks)
    Patterns.apply([swap_operator('cross', ['?to', '?from'])], methods.clear, SWAP_PREDICATES, [], tasks.clear, [], [])
    assert_equal(swap_methods(['cross'], ['?intermediate', '?current'], [['adjacent', '?intermediate', '?current']]), methods)
    assert_equal([false], tasks)
  end

  def test_swap_effect_clustering
    operators = [
      swap_operator('cross', ['?from', '?to']),
      swap_operator('walk', ['?from', '?to'], ['?from', '?to'])
    ]
    Patterns.apply(operators, methods = [], SWAP_PREDICATES, [], [], [], [])
    assert_equal(swap_methods(['cross', 'walk'], ['?current', '?intermediate'], [['adjacent', '?current', '?intermediate']]), methods)
  end

  def test_swap_multiple_constraints
    predicates = SWAP_PREDICATES.dup
    predicates['bridge'] = false
    operators = [swap_operator('cross', ['?from', '?to'])]
    Patterns.apply(operators, methods = [], predicates, [], [], [], [])
    assert_equal(swap_methods(['cross'], ['?current', '?intermediate'], [['adjacent', '?current', '?intermediate'], ['bridge', '?current', '?b', '?intermediate']], ['?current', '?intermediate', '?b', '?ag']), methods)
  end

  def test_dependency_variable_introduction
    # Based on gripper domain
    Patterns.apply(
      # Operators
      [
        ['pick', ['?obj', '?room', '?gripper'],
          # Preconditions
          [
            ['ball', '?obj'], ['room', '?room'], ['gripper', '?gripper'], ['predicate'],
            ['at', '?obj', '?room'], ['atRobby', '?room'], ['free', '?gripper']
          ],
          [],
          # Effects
          [['carry', '?obj', '?gripper']],
          [['at', '?obj', '?room'], ['free', '?gripper']]
        ],
        ['drop', ['?obj', '?room', '?gripper'],
          # Preconditions
          [
            ['ball', '?obj'], ['room', '?room'], ['gripper', '?gripper'],
            ['carry', '?obj', '?gripper'], ['atRobby', '?room']
          ],
          [],
          # Effects
          [['at', '?obj', '?room'], ['free', '?gripper']],
          [['carry', '?obj', '?gripper']]
        ]
      ],
      # Methods
      methods = [],
      # Predicates
      {
        'ball' => false,
        'room' => false,
        'gripper' => false,
        'predicate' => false,
        'at' => true,
        'atRobby' => true,
        'free' => true,
        'carry' => true
      },
      # State
      [],
      # Tasks
      tasks = [],
      # Goal_pos
      [],
      # Goal_not
      []
    )
    assert_equal([
      ['dependency_drop_before_pick_for_carry', ['?obj', '?room', '?gripper'],
        ['goal-satisfied', [],
          # Preconditions
          [['carry', '?obj', '?gripper']],
          [],
          # Subtasks
          []
        ],
        ['satisfied', [],
          # Preconditions
          [
            ['ball', '?obj'], ['room', '?room'], ['gripper', '?gripper'], ['predicate'],
            ['at', '?obj', '?room']
          ],
          [],
          # Subtasks
          [['pick', '?obj', '?room', '?gripper']]
        ],
        ['unsatisfied', [],
          # Preconditions
          [['ball', '?obj'], ['room', '?room'], ['gripper', '?gripper'], ['predicate']],
          [['at', '?obj', '?room']],
          # Subtasks
          [
            ['drop', '?obj', '?room', '?gripper'],
            ['pick', '?obj', '?room', '?gripper']
          ]
        ]
      ],
      ['dependency_pick_before_drop_for_at', ['?obj', '?room', '?gripper'],
        ['goal-satisfied', [],
          # Preconditions
          [['at', '?obj', '?room']],
          [],
          # Subtasks
          []
        ],
        ['satisfied', [],
          # Preconditions
          [
            ['ball', '?obj'], ['room', '?room'], ['gripper', '?gripper'],
            ['carry', '?obj', '?gripper']
          ],
          [],
          # Subtasks
          [['drop', '?obj', '?room', '?gripper']]
        ],
        ['unsatisfied', [],
          # Preconditions
          [['ball', '?obj'], ['room', '?room'], ['gripper', '?gripper'], ['predicate']],
          [['carry', '?obj', '?gripper']],
          # Subtasks
          [
            ['pick', '?obj', '?room', '?gripper'],
            ['drop', '?obj', '?room', '?gripper']
          ]
        ]
      ],
      ['dependency_pick_before_drop_for_free', ['?obj', '?room', '?gripper'],
        ['goal-satisfied', [],
          # Preconditions
          [['free', '?gripper']],
          [],
          # Subtasks
          []
        ],
        ['satisfied', [],
          # Preconditions
          [
            ['ball', '?obj'], ['room', '?room'], ['gripper', '?gripper'],
            ['carry', '?obj', '?gripper']
          ],
          [],
          # Subtasks
          [['drop', '?obj', '?room', '?gripper']]
        ],
        ['unsatisfied', [],
          # Preconditions
          [['ball', '?obj'], ['room', '?room'], ['gripper', '?gripper'], ['predicate']],
          [['carry', '?obj', '?gripper']],
          # Subtasks
          [
            ['pick', '?obj', '?room', '?gripper'],
            ['drop', '?obj', '?room', '?gripper']
          ]
        ]
      ]
    ], methods)
    assert_equal([false], tasks)
  end

  def test_dependency_of_swap_before_operator
    operators = [
      swap_operator('walk', ['?from', '?to']),
      ['observe', ['?ag', '?from'],
        # Preconditions
        [['at', '?ag', '?room']],
        [['observed', '?ag', '?from']],
        # Effects
        [['observed', '?ag', '?from']],
        []
      ]
    ]
    Patterns.apply(operators, methods = [], SWAP_PREDICATES, [], [], [], [])
    assert_equal([
      ['dependency_swap_at_until_at_before_observe_for_observed', ['?ag', '?room', '?from'],
        ['goal-satisfied', [],
          # Preconditions
          [['observed', '?ag', '?from']],
          [],
          # Subtasks
          []
        ],
        ['unsatisfied', [],
          # Preconditions
          [],
          [['at', '?ag', '?room']],
          # Subtasks
          [
            ['swap_at_until_at', '?ag', '?room'],
            ['observe', '?ag', '?from']
          ]
        ]
      ]
    ], methods.select {|met,| met.start_with?('dependency_')})
  end

  def test_dependency_of_operator_before_swap
    operators = [
      swap_operator('walk', ['?from', '?to']),
      ['abstract', ['?from', '?b', '?to'],
        # Preconditions
        [],
        [],
        # Effects
        [['bridge', '?from', '?b', '?to']],
        []
      ]
    ]
    Patterns.apply(operators, methods = [], SWAP_PREDICATES, [], [], [], [])
    assert_equal([
      ['dependency_abstract_before_swap_empty_until_empty_for_at', ['?from', '?b', '?to'],
        ['goal-satisfied', [], [['at', '?ag', '?to']], [], []],
        ['satisfied', [],
          # Preconditions
          [['bridge', '?from', '?b', '?to']],
          [],
          # Subtasks
          [['swap_empty_until_empty', '?to']]],
        ['unsatisfied', [],
          # Preconditions
          [],
          [['bridge', '?from', '?b', '?to']],
          # Subtasks
          [
            ['abstract', '?from', '?b', '?to'],
            ['swap_empty_until_empty', '?to']
          ]
        ]
      ],
      ['dependency_abstract_before_swap_empty_until_empty_for_empty', ['?from', '?b', '?to'],
        ['goal-satisfied', [], [['empty', '?from']], [], []],
        ['satisfied', [],
          # Preconditions
          [['bridge', '?from', '?b', '?to']],
          [],
          # Subtasks
          [['swap_empty_until_empty', '?to']]
        ],
        ['unsatisfied', [],
          # Preconditions
          [],
          [['bridge', '?from', '?b', '?to']],
          # Subtasks
          [
            ['abstract', '?from', '?b', '?to'],
            ['swap_empty_until_empty', '?to']
          ]
        ]
      ]
    ], methods.select {|met,| met.start_with?('dependency_')})
  end

  def test_task_selection
    operators = [swap_operator('cross', ['?from', '?to'])]
    state = [['agent', 'bob'], ['p'], ['p2', 'bridge'], ['adjacent' , 'a', 'b'], ['bridge', 'a', 'bridge', 'b'], ['at', 'bob', 'a'], ['empty', 'b']]
    Patterns.apply(operators, [], SWAP_PREDICATES, state, tasks = [], [], [])
    assert_equal([false], tasks)
    Patterns.apply(operators, [], SWAP_PREDICATES, state, tasks = [], [['at', 'bob', 'a']], [])
    assert_equal([false, ['swap_at_until_at', 'bob', 'a']], tasks)
    Patterns.apply(operators, [], SWAP_PREDICATES, state, tasks = [], [['at', 'bob', 'b']], [])
    assert_equal([false, ['swap_at_until_at', 'bob', 'b']], tasks)
  end
end