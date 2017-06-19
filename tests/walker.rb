require './tests/hypest'

class Walker < Test::Unit::TestCase
  include Hypest

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
      :operators => [
        ['move', ['?start', '?finish'],
          # Preconditions
          [
             ['node', '?start'],
             ['node', '?finish'],
             ['at', '?start'],
             ['connected', '?start', '?finish']
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
        ['invisible_visit_at', ['?start'],
          # Preconditions
          [],
          [],
          # Effects
          [['visited_at', '?start']],
          []
        ],
        ['invisible_unvisit_at', ['?start'],
          # Preconditions
          [],
          [],
          # Effects
          [],
          [['visited_at', '?start']]
        ]
      ],
      :methods => [
        ['swap_at_until_at', ['?start'],
          ['base', [],
            # Preconditions
            [['at', '?start']],
            [],
            # Subtasks
            []
          ],
          ['using_move', ['?current', '?intermediate'],
            # Preconditions
            [['at', '?current'], ['connected', '?current', '?intermediate']],
            [['at', '?start'], ['visited_at', '?intermediate']],
            # Subtasks
            [
              ['move', '?current', '?intermediate'],
              ['invisible_visit_at', '?current'],
              ['swap_at_until_at', '?start'],
              ['invisible_unvisit_at', '?current']
            ]
          ]
        ],
        ['swap_at_until_visited', ['?start'],
          ['base', [],
            # Preconditions
            [['visited', '?start']],
            [],
            # Subtasks
            []
          ],
          ['using_move', ['?current', '?intermediate'],
            # Preconditions
            [['at', '?current'], ['connected', '?current', '?intermediate']],
            [['at', '?start'], ['visited_at', '?intermediate']],
            # Subtasks
            [
              ['move', '?current', '?intermediate'],
              ['invisible_visit_at', '?current'],
              ['swap_at_until_visited', '?start'],
              ['invisible_unvisit_at', '?current']
            ]
          ]
        ],
      ],
      :predicates => {
        'node' => false,
        'at' => true,
        'connected' => false,
        'visited' => true,
        'visited_at' => true
      },
      :state => [
        ['node', 'boston'],
        ['node', 'newyork'],
        ['node', 'pittsburgh'],
        ['node', 'toronto'],
        ['node', 'albany'],
        ['connected', 'boston', 'newyork'],
        ['connected', 'newyork', 'boston'],
        ['connected', 'pittsburgh', 'boston'],
        ['connected', 'boston', 'pittsburgh'],
        ['connected', 'pittsburgh', 'newyork'],
        ['connected', 'newyork', 'pittsburgh'],
        ['connected', 'toronto', 'pittsburgh'],
        ['connected', 'toronto', 'newyork'],
        ['connected', 'newyork', 'toronto'],
        ['connected', 'newyork', 'albany'],
        ['connected', 'albany', 'newyork'],
        ['connected', 'albany', 'toronto'],
        ['connected', 'toronto', 'albany'],
        ['at', 'pittsburgh']
      ],
      :tasks => [false,
        ['swap_at_until_at', 'pittsburgh'],
        ['swap_at_until_visited', 'boston'],
        ['swap_at_until_visited', 'newyork'],
        ['swap_at_until_visited', 'pittsburgh'],
        ['swap_at_until_visited', 'toronto'],
        ['swap_at_until_visited', 'albany']
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
      :requirements => [':strips', ':typing', ':negative-preconditions']
    )
  end
end