require './tests/hypest'

class Paisley < Test::Unit::TestCase

  def cross_operator(parameters, constraint_terms)
    [
      ['cross', ['?agent', '?b', *parameters],
        # Preconditions
        [
          ['agent', '?ag'], ['predicate'], ['predicate2', '?b'], ['adjacent' , *constraint_terms],
          ['bridge', '?from', '?b', '?to'], ['at', '?ag', '?from'], ['empty', '?to']
        ],
        [],
        # Effects
        [['at', '?ag', '?to'], ['empty', '?from']],
        [['at', '?ag', '?from'], ['empty', '?to']]
      ]
    ]
  end

  def swap_cross_methods(parameters, constraint_terms)
    [
      ['swap_at_until_at', ['?ag', '?from'],
        ['base', [],
          # Preconditions
          [['at', '?ag', '?from']],
          [],
          []
        ],
        ['using_cross', constraint_terms,
          # Preconditions
          [['at', '?ag', '?current'], ['adjacent', *constraint_terms]],
          [['at', '?ag', '?from'], ['visited_at', '?ag', '?intermediate']],
          # Subtasks
          [
            ['cross', '?agent', '?b', *parameters],
            ['invisible_visit_at', '?ag', '?current'],
            ['swap_at_until_at', '?ag', '?from'],
            ['invisible_unvisit_at', '?ag', '?current']
          ]
        ]
      ],
      ['swap_at_until_empty', ['?ag', '?from'],
        ['base', [],
          # Preconditions
          [['empty', '?ag']],
          [],
          # Subtasks
          []
        ],
        ['using_cross', constraint_terms,
          # Preconditions
          [['at', '?ag', '?current'], ['adjacent', *constraint_terms]],
          [['at', '?ag', '?from'], ['visited_at', '?ag', '?intermediate']],
          # Subtasks
          [
            ['cross', '?agent', '?b', *parameters],
            ['invisible_visit_at', '?ag', '?current'],
            ['swap_at_until_empty', '?ag', '?from'],
            ['invisible_unvisit_at', '?ag', '?current']
          ]
        ]
      ]
    ]
  end

  def test_flexible_parameters_in_swap
    # Based on planks domain
    predicates = {
      'agent' => false,
      'predicate' => false,
      'predicate2' => false,
      'adjacent' => false,
      'at' => true,
      'bridge' => true,
      'empty' => true
    }
    Patterns.apply(cross_operator(['?from', '?to'], ['?from', '?to']), methods = [], predicates, [], tasks = [], [], [])
    assert_equal(swap_cross_methods(['?current', '?intermediate'], ['?current', '?intermediate']), methods)
    assert_equal([false], tasks)
    Patterns.apply(cross_operator(['?from', '?to'], ['?to', '?from']), methods.clear, predicates, [], tasks.clear, [], [])
    assert_equal(swap_cross_methods(['?current', '?intermediate'], ['?intermediate', '?current']), methods)
    assert_equal([false], tasks)
    Patterns.apply(cross_operator(['?to', '?from'], ['?from', '?to']), methods.clear, predicates, [], tasks.clear, [], [])
    assert_equal(swap_cross_methods(['?intermediate', '?current'], ['?current', '?intermediate']), methods)
    assert_equal([false], tasks)
    Patterns.apply(cross_operator(['?to', '?from'], ['?to', '?from']), methods.clear, predicates, [], tasks.clear, [], [])
    assert_equal(swap_cross_methods(['?intermediate', '?current'], ['?intermediate', '?current']), methods)
    assert_equal([false], tasks)
  end

  def test_variable_introduction_in_dependency
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
      'predicate' => false,
      'predicate2' => false,
      'adjacent' => false,
      'at' => true,
      'bridge' => true,
      'empty' => true
    }
    state = [['agent', 'bob'], ['predicate'], ['predicate2', 'bridge'], ['adjacent' , 'a', 'b'], ['bridge', 'a', 'bridge', 'b'], ['at', 'bob', 'a'], ['empty', 'b']]
    Patterns.apply(cross_operator(['?from', '?to'], ['?from', '?to']), [], predicates, state, tasks = [], [], [])
    assert_equal([false], tasks)
    Patterns.apply(cross_operator(['?from', '?to'], ['?from', '?to']), [], predicates, state, tasks = [], [['at', 'bob', 'a']], [])
    assert_equal([false, ['swap_at_until_at', 'bob', 'a']], tasks)
    Patterns.apply(cross_operator(['?from', '?to'], ['?from', '?to']), [], predicates, state, tasks = [], [['at', 'bob', 'b']], [])
    assert_equal([false, ['swap_at_until_at', 'bob', 'b']], tasks)
  end
end