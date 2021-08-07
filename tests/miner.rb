require './tests/hypest'
require './examples/experiments/Grid'

class Miner < Test::Unit::TestCase
  include Hypest

  def test_goldminer_pb2_pddl_parsing_with_patterns
    parser_tests(
      # Files
      'examples/goldminer/goldminer.pddl',
      'examples/goldminer/pb2.pddl',
      # Parser and extensions
      PDDL_Parser, ['patterns'],
      # Attributes
      :domain_name => 'goldminer',
      :problem_name => 'pb2',
      :operators => [
        ['move', ['?agent', '?from', '?to'],
          # Preconditions
          [
            ['at', '?agent', '?from'],
            ['adjacent', '?from', '?to'],
          ],
          [
            ['blocked', '?from'],
            ['blocked', '?to']
          ],
          # Effects
          [['at', '?agent', '?to']],
          [['at', '?agent', '?from']]
        ],
        ['pick', ['?agent', '?gold', '?pick_position'],
          # Preconditions
          [
            ['at', '?agent', '?pick_position'],
            ['on', '?gold', '?pick_position']
          ],
          [
            ['blocked', '?pick_position']
          ],
          # Effects
          [['have', '?agent', '?gold']],
          [['on', '?gold', '?pick_position']]
        ],
        ['drop', ['?agent', '?gold', '?drop_position'],
          # Preconditions
          [
            ['at', '?agent', '?drop_position'],
            ['have', '?agent', '?gold']
          ],
          [
            ['blocked', '?drop_position']
          ],
          # Effects
          [['on', '?gold', '?drop_position']],
          [['have', '?agent', '?gold']]
        ],
        ["invisible_#{Patterns::VISIT}_at", ['?agent', '?from'],
          # Preconditions
          [],
          [],
          # Effects
          [['visited_at', '?agent', '?from']],
          []
        ],
        ["invisible_un#{Patterns::VISIT}_at", ['?agent', '?from'],
          # Preconditions
          [],
          [],
          # Effects
          [],
          [['visited_at', '?agent', '?from']]
        ]
      ],
      :methods => [
        ['swap_at_until_at', ['?agent', '?to'],
          ['base', [],
            # Preconditions
            [['at', '?agent', '?to']],
            [],
            # Subtasks
            []
          ],
          ['using_move', ['?current', '?intermediate'],
            # Preconditions
            [
              ['at', '?agent', '?current'],
              ['adjacent', '?current', '?intermediate']
            ],
            [
              ['at', '?agent', '?to'],
              ['visited_at', '?agent', '?intermediate']
            ],
            # Subtasks
            [
              ['move', '?agent', '?current', '?intermediate'],
              ["invisible_#{Patterns::VISIT}_at", '?agent', '?current'],
              ['swap_at_until_at', '?agent', '?to'],
              ["invisible_un#{Patterns::VISIT}_at", '?agent', '?current']
            ]
          ]
        ],
        ['dependency_swap_at_until_at_before_pick_for_have', ['?agent', '?pick_position', '?gold'],
          ['goal-satisfied', [],
            # Preconditions
            [['have', '?agent', '?gold']],
            [],
            # Subtasks
            []
          ],
          ['unsatisfied', [],
            # Preconditions
            [],
            [
              ['blocked', '?pick_position'],
              ['at', '?agent', '?pick_position']
            ],
            # Subtasks
            [
              ['swap_at_until_at', '?agent', '?pick_position'],
              ['pick', '?agent', '?gold', '?pick_position']
            ]
          ]
        ],
        ['dependency_drop_before_pick_for_have', ['?agent', '?gold', '?drop_position', '?pick_position'],
          ['goal-satisfied', [],
            # Preconditions
            [['have', '?agent', '?gold']],
            [],
            # Subtasks
            []
          ],
          ['satisfied', [],
            # Preconditions
            [['on', '?gold', '?pick_position']],
            [['blocked', '?pick_position']],
            # Subtasks
            [['dependency_swap_at_until_at_before_pick_for_have', '?agent', '?pick_position', '?gold']]
          ],
          ['unsatisfied', [],
            # Preconditions
            [],
            [
              ['blocked', '?pick_position'],
              ['blocked', '?drop_position'],
              ['on', '?gold', '?pick_position']
            ],
            # Subtasks
            [
              ['dependency_swap_at_until_at_before_drop_for_on', '?agent', '?drop_position', '?gold'],
              ['dependency_swap_at_until_at_before_pick_for_have', '?agent', '?pick_position', '?gold']
            ]
          ]
        ],
        ['dependency_swap_at_until_at_before_drop_for_on', ['?agent', '?drop_position', '?gold'],
          ['goal-satisfied', [],
            # Preconditions
            [['on', '?gold', '?drop_position']],
            [],
            # Subtasks
            []
          ],
          ['unsatisfied', [],
            # Preconditions
            [],
            [
              ['blocked', '?drop_position'],
              ['at', '?agent', '?drop_position']
            ],
            # Subtasks
            [
              ['swap_at_until_at', '?agent', '?drop_position'],
              ['drop', '?agent', '?gold', '?drop_position']
            ]
          ]
        ],
        ['dependency_pick_before_drop_for_on', ['?agent', '?gold', '?pick_position', '?drop_position'],
          ['goal-satisfied', [],
            # Preconditions
            [['on', '?gold', '?drop_position']],
            [],
            # Subtasks
            []
          ],
          ['satisfied', [],
            # Preconditions
            [['have', '?agent', '?gold']],
            [['blocked', '?drop_position']],
            # Subtasks
            [['dependency_swap_at_until_at_before_drop_for_on', '?agent', '?drop_position', '?gold']]
          ],
          ['unsatisfied', [],
            # Preconditions
            [],
            [
              ['blocked', '?drop_position'],
              ['blocked', '?pick_position'],
              ['have', '?agent', '?gold']
            ],
            # Subtasks
            [
              ['dependency_swap_at_until_at_before_pick_for_have', '?agent', '?pick_position', '?gold'],
              ['dependency_swap_at_until_at_before_drop_for_on', '?agent', '?drop_position', '?gold']
            ]
          ]
        ],
        ['unify_agent_pick_position_before_dependency_pick_before_drop_for_on', ['?gold', '?drop_position'],
          ['agent_pick_position_from', ['?agent', '?pick_position', '?from'],
            # Preconditions
            [
              ['at', '?agent', '?from'],
              ['on', '?gold', '?pick_position']
            ],
            [
              ['blocked', '?drop_position'],
              ['blocked', '?pick_position']
            ],
            # Subtasks
            [['dependency_pick_before_drop_for_on', '?agent', '?gold', '?pick_position', '?drop_position']]
          ]
        ]
      ],
      :predicates => {
        'adjacent' => false,
        'at' => true,
        'blocked' => false,
        'have' => true,
        'on' => true,
        'visited_at' => true
      },
      :state => {
        'adjacent' => Grid.generate(10,10),
        'at' => [['ag1', 'p1_6']],
        'on' => [['g1', 'p4_0'], ['g2', 'p4_3'], ['g3', 'p5_9']],
        'blocked' => [
          ['p1_1'], ['p2_1'], ['p3_1'], ['p4_1'], ['p5_1'], ['p6_1'], ['p7_1'], ['p8_1'],
          ['p3_6'], ['p6_6'],
          ['p3_7'], ['p6_7'],
          ['p1_8'], ['p2_8'], ['p3_8'], ['p6_8'], ['p7_8'], ['p8_8']
        ]
      },
      :tasks => [false,
        ['unify_agent_pick_position_before_dependency_pick_before_drop_for_on', 'g1', 'p8_6'],
        ['unify_agent_pick_position_before_dependency_pick_before_drop_for_on', 'g2', 'p8_6'],
        ['unify_agent_pick_position_before_dependency_pick_before_drop_for_on', 'g3', 'p8_6']
      ],
      :goal_pos => [
        ['on', 'g1', 'p8_6'],
        ['on', 'g2', 'p8_6'],
        ['on', 'g3', 'p8_6']
      ],
      :goal_not => [],
      :objects => ['ag1', 'g1', 'g2', 'g3'].concat(Grid.objects(10,10).flatten!(1)),
      :requirements => [':strips', ':negative-preconditions']
    )
  end
end