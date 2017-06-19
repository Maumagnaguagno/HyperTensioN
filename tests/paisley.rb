require './tests/hypest'

class Paisley < Test::Unit::TestCase

  def test_flexible_parameters_in_swap
    # Based on planks domain
    methods = []
    Patterns.apply(
      # Operators
      [
        ['cross', ['?agent', '?b', '?from', '?to'],
          # Preconditions
          [
            ['agent', '?ag'], ['predicate', '?b'], ['adjacent' , '?from', '?to'],
            ['bridge', '?from', '?b', '?to'], ['at', '?ag', '?from'], ['empty', '?to']
          ],
          [],
          # Effects
          [['at', '?ag', '?to'], ['empty', '?from']],
          [['at', '?ag', '?from'], ['empty', '?to']]
        ]
      ],
      # Methods
      methods,
      # Predicates
      {
        'agent' => false,
        'predicate' => false,
        'adjacent' => false,
        'at' => true,
        'bridge' => true,
        'empty' => true
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
        ['swap_at_until_at', ['?ag', '?from'],
          ['base', [],
            # Preconditions
            [['at', '?ag', '?from']],
            [],
            []
          ],
          ['using_cross', ['?current', '?intermediate'],
            # Preconditions
            [['at', '?ag', '?current'], ['adjacent', '?current', '?intermediate']],
            [['at', '?ag', '?from'], ['visited_at', '?ag', '?intermediate']],
            # Subtasks
            [
              ['cross', '?agent', '?b', '?current', '?intermediate'],
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
          ['using_cross', ['?current', '?intermediate'],
            # Preconditions
            [['at', '?ag', '?current'], ['adjacent', '?current', '?intermediate']],
            [['at', '?ag', '?from'], ['visited_at', '?ag', '?intermediate']],
            # Subtasks
            [
              ['cross', '?agent', '?b', '?current', '?intermediate'],
              ['invisible_visit_at', '?ag', '?current'],
              ['swap_at_until_empty', '?ag', '?from'],
              ['invisible_unvisit_at', '?ag', '?current']
            ]
          ]
        ]
      ],
      methods
    )
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