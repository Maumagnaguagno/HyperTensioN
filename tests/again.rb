require 'test/unit'
require './extensions/Dejavu'

class Again < Test::Unit::TestCase

  def test_dejavu_indirect_recursion
    methods = [
      ['m1', ['?a', '?b'],
        ['base', [],
          # Preconditions
          [],
          [],
          # Subtasks
          []
        ],
        ['recursion', ['?c'],
          # Preconditions
          [],
          [],
          # Subtasks
          [
            ['m2', '?a', '?b', '?c'],
          ]
        ]
      ],
      ['m2', ['?a', '?b', '?c'],
        ['base', [],
          # Preconditions
          [],
          [],
          # Subtasks
          []
        ],
        ['recursion', [],
          # Preconditions
          [],
          [],
          # Subtasks
          [
            ['m1', '?a', '?b'],
          ]
        ]
      ]
    ]
    Dejavu.apply(operators = [], methods, predicates = {}, nil, tasks = [true, ['m1','bob','home']], nil, nil)
    assert_equal(
      [
        ['invisible_visit_m2_recursion_0', ['?a', '?b'],
          # Preconditions
          [],
          [],
          # Effects
          [['visited_m2_recursion_0', '?a', '?b']],
          []
        ],
        ['invisible_unvisit_m2_recursion_0', ['?a', '?b'],
          # Preconditions
          [],
          [],
          # Effects
          [],
          [['visited_m2_recursion_0', '?a', '?b']]
        ]
      ], operators
    )
    assert_equal([
      ['m1', ['?a', '?b'],
        ['base', [],
          # Preconditions
          [],
          [],
          # Subtasks
          []
        ],
        ['recursion', ['?c'],
          # Preconditions
          [],
          [],
          # Subtasks
          [
            ['m2', '?a', '?b', '?c'],
          ]
        ]
      ],
      ['m2', ['?a', '?b', '?c'],
        ['base', [],
          # Preconditions
          [],
          [],
          # Subtasks
          []
        ],
        ['recursion', [],
          # Preconditions
          [],
          [
            ['visited_m2_recursion_0', '?a', '?b']
          ],
          # Subtasks
          [
            ['invisible_visit_m2_recursion_0', '?a', '?b'],
            ['m1', '?a', '?b'],
            ['invisible_unvisit_m2_recursion_0', '?a', '?b'],
          ]
        ]
      ]
    ], methods)
    assert_equal({'visited_m2_recursion_0' => true}, predicates)
    assert_equal([true, ['m1','bob','home']], tasks)
  end
end