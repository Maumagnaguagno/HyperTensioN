require './tests/hypest'

class Simple < Test::Unit::TestCase
  include Hypest

  def test_basic_pb1_pddl_parsing_with_patterns
    parser_tests(
      # Files
      'examples/basic/basic.pddl',
      'examples/basic/pb3.pddl',
      # Parser and extensions
      PDDL_Parser, ['patterns'],
      # Attributes
      :domain_name => 'basic',
      :problem_name => 'pb3',
      :operators => [
        ['pickup', ['?a'],
          # Preconditions
          [],
          [['have','?a']],
          # Effects
          [['have','?a']],
          []
        ],
        ['drop', ['?a'],
          # Preconditions
          [['have','?a']],
          [],
          # Effects
          [],
          [['have','?a']]
        ]
      ],
      :methods => [],
      :predicates => {
        'have' => true
      },
      :state => [
        ['have', 'kiwi']
      ],
      :tasks => [false,
        ['pickup', 'banjo'],
        ['drop', 'kiwi']
      ],
      :goal_pos => [
        ['have', 'banjo']
      ],
      :goal_not => [
        ['have', 'kiwi']
      ],
      :objects => ['kiwi', 'banjo'],
      :requirements => [':strips', ':negative-preconditions']
    )
  end
end