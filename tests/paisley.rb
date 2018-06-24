require './tests/hypest'

class Paisley < Test::Unit::TestCase

  def cross_operator(parameters, constraint_terms)
    [
      ['cross', ['?agent', '?b', *parameters],
        # Preconditions
        [
          ['agent', '?ag'], ['predicate', '?b'], ['adjacent' , *constraint_terms],
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
      'adjacent' => false,
      'at' => true,
      'bridge' => true,
      'empty' => true
    }
    methods = []

    Patterns.apply(cross_operator(['?from', '?to'], ['?from', '?to']), methods, predicates, [], [], [], [])
    assert_equal(swap_cross_methods(['?current', '?intermediate'], ['?current', '?intermediate']), methods)
    methods.clear
    Patterns.apply(cross_operator(['?from', '?to'], ['?to', '?from']), methods, predicates, [], [], [], [])
    assert_equal(swap_cross_methods(['?current', '?intermediate'], ['?intermediate', '?current']), methods)
    methods.clear
    Patterns.apply(cross_operator(['?to', '?from'], ['?from', '?to']), methods, predicates, [], [], [], [])
    assert_equal(swap_cross_methods(['?intermediate', '?current'], ['?current', '?intermediate']), methods)
    methods.clear
    Patterns.apply(cross_operator(['?to', '?from'], ['?to', '?from']), methods, predicates, [], [], [], [])
    assert_equal(swap_cross_methods(['?intermediate', '?current'], ['?intermediate', '?current']), methods)
  end

  def test_variable_introduction_in_dependency
    # Based on gripper domain
    methods = []
    Patterns.apply(
      # Operators
      [
        ['pick', ['?obj', '?room', '?gripper'],
          # Preconditions
          [
            ['ball', '?obj'], ['room', '?room'], ['gripper', '?gripper'],
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
      methods,
      # Predicates
      {
        'ball' => false,
        'room' => false,
        'gripper' => false,
        'at' => true,
        'atRobby' => true,
        'free' => true,
        'carry' => true
      },
      # State
      [],
      # Tasks
      [],
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
              ['ball', '?obj'], ['room', '?room'], ['gripper', '?gripper'],
              ['at', '?obj', '?room']
            ],
            [],
            # Subtasks
            [['pick', '?obj', '?room', '?gripper']]
          ],
          ['unsatisfied', [],
            # Preconditions
            [['ball', '?obj'], ['room', '?room'], ['gripper', '?gripper']],
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
            [['ball', '?obj'], ['room', '?room'], ['gripper', '?gripper']],
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
            [['ball', '?obj'], ['room', '?room'], ['gripper', '?gripper']],
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
  end
end