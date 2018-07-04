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
        ['invisible_visit_at', ['?agent', '?from'],
          # Preconditions
          [],
          [],
          # Effects
          [['visited_at', '?agent', '?from']],
          []
        ],
        ['invisible_unvisit_at', ['?agent', '?from'],
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
              ['invisible_visit_at', '?agent', '?current'],
              ['swap_at_until_at', '?agent', '?to'],
              ['invisible_unvisit_at', '?agent', '?current']
            ]
          ]
        ],
        ['dependency_swap_at_until_at_before_pick_for_have', ['?agent', '?gold', '?pick_position'],
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
            [['dependency_swap_at_until_at_before_pick_for_have', '?agent', '?gold', '?pick_position']]
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
              ['dependency_swap_at_until_at_before_drop_for_on', '?agent', '?gold', '?drop_position'],
              ['dependency_swap_at_until_at_before_pick_for_have', '?agent', '?gold', '?pick_position']
            ]
          ]
        ],
        ['dependency_swap_at_until_at_before_drop_for_on', ['?agent', '?gold', '?drop_position'],
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
            [['dependency_swap_at_until_at_before_drop_for_on', '?agent', '?gold', '?drop_position']]
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
              ['dependency_swap_at_until_at_before_pick_for_have', '?agent', '?gold', '?pick_position'],
              ['dependency_swap_at_until_at_before_drop_for_on', '?agent', '?gold', '?drop_position']
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
      :state => Grid.generate(10,10).map! {|i| i.unshift('adjacent')}.push(
        ['at', 'ag1', 'p1_6'],
        ['on', 'g1', 'p4_0'],
        ['on', 'g2', 'p4_3'],
        ['on', 'g3', 'p5_9'],
        ['blocked', 'p1_1'],
        ['blocked', 'p2_1'],
        ['blocked', 'p3_1'],
        ['blocked', 'p4_1'],
        ['blocked', 'p5_1'],
        ['blocked', 'p6_1'],
        ['blocked', 'p7_1'],
        ['blocked', 'p8_1'],
        ['blocked', 'p3_6'],
        ['blocked', 'p6_6'],
        ['blocked', 'p3_7'],
        ['blocked', 'p6_7'],
        ['blocked', 'p1_8'],
        ['blocked', 'p2_8'],
        ['blocked', 'p3_8'],
        ['blocked', 'p6_8'],
        ['blocked', 'p7_8'],
        ['blocked', 'p8_8']
      ),
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
      :objects => ['ag1', 'g1', 'g2', 'g3',
        'p0_0', 'p0_1', 'p0_2', 'p0_3', 'p0_4', 'p0_5', 'p0_6', 'p0_7', 'p0_8', 'p0_9',
        'p1_0', 'p1_1', 'p1_2', 'p1_3', 'p1_4', 'p1_5', 'p1_6', 'p1_7', 'p1_8', 'p1_9',
        'p2_0', 'p2_1', 'p2_2', 'p2_3', 'p2_4', 'p2_5', 'p2_6', 'p2_7', 'p2_8', 'p2_9',
        'p3_0', 'p3_1', 'p3_2', 'p3_3', 'p3_4', 'p3_5', 'p3_6', 'p3_7', 'p3_8', 'p3_9',
        'p4_0', 'p4_1', 'p4_2', 'p4_3', 'p4_4', 'p4_5', 'p4_6', 'p4_7', 'p4_8', 'p4_9',
        'p5_0', 'p5_1', 'p5_2', 'p5_3', 'p5_4', 'p5_5', 'p5_6', 'p5_7', 'p5_8', 'p5_9',
        'p6_0', 'p6_1', 'p6_2', 'p6_3', 'p6_4', 'p6_5', 'p6_6', 'p6_7', 'p6_8', 'p6_9',
        'p7_0', 'p7_1', 'p7_2', 'p7_3', 'p7_4', 'p7_5', 'p7_6', 'p7_7', 'p7_8', 'p7_9',
        'p8_0', 'p8_1', 'p8_2', 'p8_3', 'p8_4', 'p8_5', 'p8_6', 'p8_7', 'p8_8', 'p8_9',
        'p9_0', 'p9_1', 'p9_2', 'p9_3', 'p9_4', 'p9_5', 'p9_6', 'p9_7', 'p9_8', 'p9_9'],
      :requirements => [':strips', ':negative-preconditions']
    )
  end
end