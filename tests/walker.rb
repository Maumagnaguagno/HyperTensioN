require './tests/hypest'

class Walker < Test::Unit::TestCase
  include Hypest

  MOVE = ['move', ['?start', '?finish'],
    # Preconditions
    [['at', '?start'], ['connected', '?start', '?finish']],
    [['visited', '?finish']],
    # Effects
    [['at', '?finish'], ['visited', '?finish']],
    [['at', '?start']]
  ]

  INVISIBLE_VISIT_AT = ['invisible_visit_at', ['?start'],
    # Preconditions
    [],
    [],
    # Effects
    [['visited_at', '?start']],
    []
  ]

  INVISIBLE_UNVISIT_AT = ['invisible_unvisit_at', ['?start'],
    # Preconditions
    [],
    [],
    # Effects
    [],
    [['visited_at', '?start']]
  ]

  STATE = {
    'connected' => [
      ['boston', 'newyork'],
      ['newyork', 'boston'],
      ['pittsburgh', 'boston'],
      ['boston', 'pittsburgh'],
      ['pittsburgh', 'newyork'],
      ['newyork', 'pittsburgh'],
      ['toronto', 'pittsburgh'],
      ['toronto', 'newyork'],
      ['newyork', 'toronto'],
      ['newyork', 'albany'],
      ['albany', 'newyork'],
      ['albany', 'toronto'],
      ['toronto', 'albany'],
    ],
    'at' => [['pittsburgh']]
  }

  def test_tsp_pb1_pddl_parsing
    parser_tests(
      # Files
      'examples/tsp/tsp.pddl',
      'examples/tsp/pb1.pddl',
      # Parser and extensions
      PDDL_Parser, [],
      # Attributes
      :domain_name => 'tsp',
      :problem_name => 'pb1',
      :operators => [MOVE],
      :methods => [],
      :predicates => {
        'at' => true,
        'connected' => false,
        'visited' => true
      },
      :state => STATE,
      :tasks => [],
      :goal_pos => [
        ['at', 'pittsburgh'],
        ['visited', 'boston'],
        ['visited', 'newyork'],
        ['visited', 'pittsburgh'],
        ['visited', 'toronto'],
        ['visited', 'albany']
      ],
      :goal_not => [],
      :objects => ['boston', 'newyork', 'pittsburgh', 'toronto', 'albany'],
      :requirements => [':strips', ':negative-preconditions']
    )
  end

  def test_tsp_pb1_pddl_parsing_with_patterns
    parser_tests(
      # Files
      'examples/tsp/tsp.pddl',
      'examples/tsp/pb1.pddl',
      # Parser and extensions
      PDDL_Parser, ['patterns'],
      # Attributes
      :domain_name => 'tsp',
      :problem_name => 'pb1',
      :operators => [MOVE, INVISIBLE_VISIT_AT, INVISIBLE_UNVISIT_AT],
      :methods => [
        ['swap_at_until_at', ['?finish'],
          ['base', [],
            # Preconditions
            [['at', '?finish']],
            [],
            # Subtasks
            []
          ],
          ['using_move', ['?current', '?intermediate'],
            # Preconditions
            [['at', '?current'], ['connected', '?current', '?intermediate']],
            [['at', '?finish'], ['visited_at', '?intermediate']],
            # Subtasks
            [
              ['move', '?current', '?intermediate'],
              ['invisible_visit_at', '?current'],
              ['swap_at_until_at', '?finish'],
              ['invisible_unvisit_at', '?current']
            ]
          ]
        ],
        ['swap_at_until_visited', ['?finish'],
          ['base', [],
            # Preconditions
            [['visited', '?finish']],
            [],
            # Subtasks
            []
          ],
          ['using_move', ['?current', '?intermediate'],
            # Preconditions
            [['at', '?current'], ['connected', '?current', '?intermediate']],
            [['at', '?finish'], ['visited_at', '?intermediate']],
            # Subtasks
            [
              ['move', '?current', '?intermediate'],
              ['invisible_visit_at', '?current'],
              ['swap_at_until_visited', '?finish'],
              ['invisible_unvisit_at', '?current']
            ]
          ]
        ],
      ],
      :predicates => {
        'at' => true,
        'connected' => false,
        'visited' => true,
        'visited_at' => true
      },
      :state => STATE,
      :tasks => [false,
        ['swap_at_until_visited', 'boston'],
        ['swap_at_until_visited', 'newyork'],
        ['swap_at_until_visited', 'pittsburgh'],
        ['swap_at_until_visited', 'toronto'],
        ['swap_at_until_visited', 'albany'],
        ['swap_at_until_at', 'pittsburgh']
      ],
      :goal_pos => [
        ['at', 'pittsburgh'],
        ['visited', 'boston'],
        ['visited', 'newyork'],
        ['visited', 'pittsburgh'],
        ['visited', 'toronto'],
        ['visited', 'albany']
      ],
      :goal_not => [],
      :objects => ['boston', 'newyork', 'pittsburgh', 'toronto', 'albany'],
      :requirements => [':strips', ':negative-preconditions']
    )
  end

  def test_tsp_pb1_pddl_parsing_with_patterns_and_pullup
    parser_tests(
      # Files
      'examples/tsp/tsp.pddl',
      'examples/tsp/pb1.pddl',
      # Parser and extensions
      PDDL_Parser, ['patterns', 'pullup'],
      # Attributes
      :domain_name => 'tsp',
      :problem_name => 'pb1',
      :operators => [
        ['move', ['?start', '?finish'],
          # Preconditions
          [
            ['at', '?start'],
          ],
          [
            ['visited', '?finish']
          ],
          # Effects
          [
            ['at', '?finish'],
            ['visited', '?finish']
          ],
          [
            ['at', '?start']
          ]
        ],
        INVISIBLE_VISIT_AT,
        INVISIBLE_UNVISIT_AT
      ],
      :methods => [
        ['swap_at_until_at', ['?finish'],
          ['base', [],
            # Preconditions
            [['at', '?finish']],
            [],
            # Subtasks
            []
          ],
          ['using_move', ['?current', '?intermediate'],
            # Preconditions
            [['at', '?current'], ['connected', '?current', '?intermediate']],
            [['at', '?finish'], ['visited_at', '?intermediate'], ['visited', '?intermediate']],
            # Subtasks
            [
              ['move', '?current', '?intermediate'],
              ['invisible_visit_at', '?current'],
              ['swap_at_until_at', '?finish'],
              ['invisible_unvisit_at', '?current']
            ]
          ]
        ],
        ['swap_at_until_visited', ['?finish'],
          ['base', [],
            # Preconditions
            [['visited', '?finish']],
            [],
            # Subtasks
            []
          ],
          ['using_move', ['?current', '?intermediate'],
            # Preconditions
            [['at', '?current'], ['connected', '?current', '?intermediate']],
            [['at', '?finish'], ['visited_at', '?intermediate'], ['visited', '?intermediate']],
            # Subtasks
            [
              ['move', '?current', '?intermediate'],
              ['invisible_visit_at', '?current'],
              ['swap_at_until_visited', '?finish'],
              ['invisible_unvisit_at', '?current']
            ]
          ]
        ],
      ],
      :predicates => {
        'at' => true,
        'connected' => false,
        'visited' => true,
        'visited_at' => true
      },
      :state => STATE,
      :tasks => [false,
        ['swap_at_until_visited', 'boston'],
        ['swap_at_until_visited', 'newyork'],
        ['swap_at_until_visited', 'pittsburgh'],
        ['swap_at_until_visited', 'toronto'],
        ['swap_at_until_visited', 'albany'],
        ['swap_at_until_at', 'pittsburgh']
      ],
      :goal_pos => [
        ['at', 'pittsburgh'],
        ['visited', 'boston'],
        ['visited', 'newyork'],
        ['visited', 'pittsburgh'],
        ['visited', 'toronto'],
        ['visited', 'albany']
      ],
      :goal_not => [],
      :objects => ['boston', 'newyork', 'pittsburgh', 'toronto', 'albany'],
      :requirements => [':strips', ':negative-preconditions']
    )
  end
end