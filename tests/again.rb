require 'test/unit'
require './extensions/Dejavu'

class Again < Test::Unit::TestCase

  def visit_operators(name, label)
    [
      ["invisible_#{name}_#{label}", ['?a', '?b'],
        # Preconditions
        [],
        [],
        # Effects
        [["visited_#{label}", '?a', '?b']],
        []
      ],
      ["invisible_un#{name}_#{label}", ['?a', '?b'],
        # Preconditions
        [],
        [],
        # Effects
        [],
        [["visited_#{label}", '?a', '?b']]
      ]
    ]
  end

  def test_dejavu_direct_recursion
    methods = [
      ['m1', ['?a', '?b'],
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
            ['m1', '?a', '?b']
          ]
        ]
      ]
    ]
    Dejavu.apply(operators = [], methods, predicates = {}, nil, tasks = [true, ['m1','bob','home']], nil, nil)
    assert_equal(visit_operators('visit', 'm1_recursion_0'), operators)
    assert_equal([
      ['m1', ['?a', '?b'],
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
          [['visited_m1_recursion_0', '?a', '?b']],
          # Subtasks
          [
            ['invisible_visit_m1_recursion_0', '?a', '?b'],
            ['m1', '?a', '?b'],
            ['invisible_unvisit_m1_recursion_0', '?a', '?b']
          ]
        ]
      ]
    ], methods)
    assert_equal({'visited_m1_recursion_0' => true}, predicates)
    assert_equal([true, ['m1','bob','home']], tasks)
  end

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
            ['m2', '?a', '?b', '?c']
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
            ['m1', '?a', '?b']
          ]
        ]
      ]
    ]
    Dejavu.apply(operators = [], methods, predicates = {}, nil, tasks = [true, ['m1','bob','home']], nil, nil)
    assert_equal(visit_operators('visit', 'm2_recursion_0'), operators)
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
            ['m2', '?a', '?b', '?c']
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
          [['visited_m2_recursion_0', '?a', '?b']],
          # Subtasks
          [
            ['invisible_visit_m2_recursion_0', '?a', '?b'],
            ['m1', '?a', '?b'],
            ['invisible_unvisit_m2_recursion_0', '?a', '?b']
          ]
        ]
      ]
    ], methods)
    assert_equal({'visited_m2_recursion_0' => true}, predicates)
    assert_equal([true, ['m1','bob','home']], tasks)
  end

  def test_dejavu_multiple
    methods = [
      ['m0', ['?a', '?b'],
        ['base', [],
          # Preconditions
          [],
          [],
          # Subtasks
          [
            ['m0', '?a', '?b']
          ]
        ],
        ['recursion', [],
          # Preconditions
          [],
          [],
          # Subtasks
          [
            ['m0', '?a', '?b'],
            ['m0', '?a', '?b']
          ]
        ]
      ]
    ]
    Dejavu.apply(operators = [], methods, predicates = {}, nil, tasks = [true, ['m0','bob','home']], nil, nil)
    assert_equal(visit_operators('mark', 'm0_base_0').concat(visit_operators('visit', 'm0_recursion_0'), visit_operators('visit', 'm0_recursion_3')), operators)
    assert_equal([
      ['m0', ['?a', '?b'],
        ['base', [],
          # Preconditions
          [],
          [['visited_m0_base_0', '?a', '?b']],
          # Subtasks
          [
            ['invisible_mark_m0_base_0', '?a', '?b'],
            ['m0', '?a', '?b'],
            ['invisible_unmark_m0_base_0', '?a', '?b']
          ]
        ],
        ['recursion', [],
          # Preconditions
          [],
          [
            ['visited_m0_recursion_0', '?a', '?b'],
            ['visited_m0_recursion_3', '?a', '?b']
          ],
          # Subtasks
          [
            ['invisible_visit_m0_recursion_0', '?a', '?b'],
            ['m0', '?a', '?b'],
            ['invisible_unvisit_m0_recursion_0', '?a', '?b'],
            ['invisible_visit_m0_recursion_3', '?a', '?b'],
            ['m0', '?a', '?b'],
            ['invisible_unvisit_m0_recursion_3', '?a', '?b']
          ]
        ]
      ],
    ], methods)
    assert_equal({'visited_m0_base_0' => true, 'visited_m0_recursion_0' => true, 'visited_m0_recursion_3' => true}, predicates)
    assert_equal([true, ['m0','bob','home']], tasks)
  end

  def test_dejavu_mark
    methods = [
      ['m0', ['?a', '?b'],
        ['base', [],
          # Preconditions
          [],
          [],
          # Subtasks
          [
            ['m0', '?a', '?b']
          ]
        ],
        ['recursion', [],
          # Preconditions
          [],
          [],
          # Subtasks
          [
            ['m0', '?a', '?b']
          ]
        ]
      ],
      ['m1', ['?a', '?b'],
        ['base', [],
          # Preconditions
          [],
          [],
          # Subtasks
          [
            ['m2', '?a', '?b', '?c']
          ]
        ],
        ['recursion', ['?c'],
          # Preconditions
          [],
          [],
          # Subtasks
          [
            ['m1', '?a', '?b', '?c']
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
            ['m1', '?a', '?b']
          ]
        ]
      ]
    ]
    Dejavu.apply(operators = [], methods, predicates = {}, nil, tasks = [true, ['m0','bob','home'], ['m1','bob','home']], nil, nil)
    assert_equal(visit_operators('mark', 'm0_base_0').concat(visit_operators('visit', 'm0_recursion_0')).concat(visit_operators('visit', 'm2_recursion_0')), operators)
    assert_equal([
      ['m0', ['?a', '?b'],
        ['base', [],
          # Preconditions
          [],
          [['visited_m0_base_0', '?a', '?b']],
          # Subtasks
          [
            ['invisible_mark_m0_base_0', '?a', '?b'],
            ['m0', '?a', '?b'],
            ['invisible_unmark_m0_base_0', '?a', '?b']
          ]
        ],
        ['recursion', [],
          # Preconditions
          [],
          [['visited_m0_recursion_0', '?a', '?b']],
          # Subtasks
          [
            ['invisible_visit_m0_recursion_0', '?a', '?b'],
            ['m0', '?a', '?b'],
            ['invisible_unvisit_m0_recursion_0', '?a', '?b']
          ]
        ]
      ],
      ['m1', ['?a', '?b'],
        ['base', [],
          # Preconditions
          [],
          [],
          # Subtasks
          [
            ['m2', '?a', '?b', '?c']
          ]
        ],
        ['recursion', ['?c'],
          # Preconditions
          [],
          [],
          # Subtasks
          [
            ['m1', '?a', '?b', '?c']
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
          [['visited_m2_recursion_0', '?a', '?b']],
          # Subtasks
          [
            ['invisible_visit_m2_recursion_0', '?a', '?b'],
            ['m1', '?a', '?b'],
            ['invisible_unvisit_m2_recursion_0', '?a', '?b']
          ]
        ]
      ]
    ], methods)
    assert_equal({'visited_m0_base_0' => true, 'visited_m0_recursion_0' => true, 'visited_m2_recursion_0' => true}, predicates)
    assert_equal([true, ['m0','bob','home'], ['m1','bob','home']], tasks)
  end
end