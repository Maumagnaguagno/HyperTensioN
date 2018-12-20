require './tests/hypest'

class Paisley < Test::Unit::TestCase

  def swap_operator(name, parameters, constraint_terms = parameters, pos_effect = [['at', '?ag', '?to'], ['empty', '?from']])
    [name, ['?ag', '?b', *parameters],
      # Preconditions
      [
        ['agent', '?ag'], ['p'], ['p2', '?b'], ['adjacent' , *constraint_terms],
        ['bridge', '?from', '?b', '?to'], ['at', '?ag', '?from'], ['empty', '?to']
      ],
      [],
      # Effects
      pos_effect,
      [['at', '?ag', '?from'], ['empty', '?to']]
    ]
  end

  def swap_methods(names, parameters, precond_pos)
    methods = [
      ['swap_at_until_at', ['?ag', '?to'],
        ['base', [],
          # Preconditions
          [['at', '?ag', '?to']],
          [],
          []
        ],
      ],
      ['swap_at_until_empty', ['?ag', '?to'],
        ['base', [],
          # Preconditions
          [['empty', '?from']],
          [],
          # Subtasks
          []
        ]
      ]
    ]
    free_variables = parameters.dup.sort! << '?middle_0'
    precond_pos.unshift(['at', '?ag', '?current'])
    names.each {|name|
      methods.first << ["using_#{name}", free_variables,
        # Preconditions
        precond_pos,
        [['at', '?ag', '?to'], ['visited_at', '?ag', '?intermediate']],
        # Subtasks
        [
          [name, '?ag', '?middle_0', *parameters],
          ['invisible_visit_at', '?ag', '?current'],
          ['swap_at_until_at', '?ag', '?to'],
          ['invisible_unvisit_at', '?ag', '?current']
        ]
      ]
      methods.last << ["using_#{name}", free_variables,
        # Preconditions
        precond_pos,
        [['at', '?ag', '?to'], ['visited_at', '?ag', '?intermediate']],
        # Subtasks
        [
          [name, '?ag', '?middle_0', *parameters],
          ['invisible_visit_at', '?ag', '?current'],
          ['swap_at_until_empty', '?ag', '?to'],
          ['invisible_unvisit_at', '?ag', '?current']
        ]
      ]
    }
    methods
  end

  def test_swap_flexible_parameters
    # Based on planks domain
    predicates = {
      'agent' => false,
      'p' => false,
      'p2' => false,
      'adjacent' => false,
      'at' => true,
      'bridge' => true,
      'empty' => true
    }
    Patterns.apply([swap_operator('cross', ['?from', '?to'])], methods = [], predicates, [], tasks = [], [], [])
    assert_equal(swap_methods(['cross'], ['?current', '?intermediate'], [['adjacent', '?current', '?intermediate']]), methods)
    assert_equal([false], tasks)
    Patterns.apply([swap_operator('cross', ['?from', '?to'], ['?to', '?from'])], methods.clear, predicates, [], tasks.clear, [], [])
    assert_equal(swap_methods(['cross'], ['?current', '?intermediate'], [['adjacent', '?intermediate', '?current']]), methods)
    assert_equal([false], tasks)
    Patterns.apply([swap_operator('cross', ['?to', '?from'], ['?from', '?to'])], methods.clear, predicates, [], tasks.clear, [], [])
    assert_equal(swap_methods(['cross'], ['?intermediate', '?current'], [['adjacent', '?current', '?intermediate']]), methods)
    assert_equal([false], tasks)
    Patterns.apply([swap_operator('cross', ['?to', '?from'])], methods.clear, predicates, [], tasks.clear, [], [])
    assert_equal(swap_methods(['cross'], ['?intermediate', '?current'], [['adjacent', '?intermediate', '?current']]), methods)
    assert_equal([false], tasks)
  end

  def test_swap_effect_clustering
    predicates = {
      'agent' => false,
      'p' => false,
      'p2' => false,
      'adjacent' => false,
      'at' => true,
      'bridge' => true,
      'empty' => true
    }
    operators = [
      swap_operator('cross', ['?from', '?to']),
      swap_operator('walk', ['?from', '?to'], ['?from', '?to'], [['at', '?ag', '?to']])
    ]
    Patterns.apply(operators, methods = [], predicates, [], [], [], [])
    assert_equal(swap_methods(['cross', 'walk'], ['?current', '?intermediate'], [['adjacent', '?current', '?intermediate']]), methods)
  end

  def test_swap_multiple_constraints
    predicates = {
      'agent' => false,
      'p' => false,
      'p2' => false,
      'adjacent' => false,
      'at' => true,
      'bridge' => false,
      'empty' => true
    }
    operators = [swap_operator('cross', ['?from', '?to'])]
    Patterns.apply(operators, methods = [], predicates, [], [], [], [])
    assert_equal(swap_methods(['cross'], ['?current', '?intermediate'], [['adjacent', '?current', '?intermediate'], ['bridge', '?current', '?middle_0', '?intermediate']]), methods)
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
    assert_equal(
      [
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
      ],
      methods
    )
    assert_equal([false], tasks)
  end

  def test_task_selection
    predicates = {
      'agent' => false,
      'p' => false,
      'p2' => false,
      'adjacent' => false,
      'at' => true,
      'bridge' => true,
      'empty' => true
    }
    operators = [swap_operator('cross', ['?from', '?to'])]
    state = [['agent', 'bob'], ['p'], ['p2', 'bridge'], ['adjacent' , 'a', 'b'], ['bridge', 'a', 'bridge', 'b'], ['at', 'bob', 'a'], ['empty', 'b']]
    Patterns.apply(operators, [], predicates, state, tasks = [], [], [])
    assert_equal([false], tasks)
    Patterns.apply(operators, [], predicates, state, tasks = [], [['at', 'bob', 'a']], [])
    assert_equal([false, ['swap_at_until_at', 'bob', 'a']], tasks)
    Patterns.apply(operators, [], predicates, state, tasks = [], [['at', 'bob', 'b']], [])
    assert_equal([false, ['swap_at_until_at', 'bob', 'b']], tasks)
  end
end