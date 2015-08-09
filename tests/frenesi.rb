require 'test/unit'
require './Hype'

class Frenesi < Test::Unit::TestCase

  def parser_tests(domain, problem, expected_parser, expected)
    Hype.parse(domain, problem)
    parser = Hype.parser
    assert_equal(expected_parser, parser)
    expected.each {|att,value| assert_equal(value, parser.send(att))}
  end

  def test_basic_jshop_parsing
    parser_tests(
      # Files
      './examples/basic_jshop/basic.jshop',
      './examples/basic_jshop/problem.jshop',
      # Parser
      JSHOP_Parser,
      # Attributes
      :domain_name => 'basic',
      :problem_name => 'problem',
      :operators => [
        ['pickup', ['?a'], [], [], [['have', '?a']], []],
        ['drop', ['?a'], [['have', '?a']], [], [], [['have', '?a']]]
      ],
      :methods => [
        ['swap', ['?x', '?y'],
          ['swap_0',
           [],
           [['have', '?x']],
           [['have', '?y']],
           [['drop', '?x'], ['pickup', '?y']]
          ],
          ['swap_1',
           [],
           [['have', '?y']],
           [['have', '?x']],
           [['drop', '?y'], ['pickup', '?x']]
          ]
        ]
      ],
      :predicates => {'have' => true},
      :state => [['have','kiwi']],
      :tasks => [true, ['swap', 'banjo', 'kiwi']],
      :goal_pos => [],
      :goal_not => []
    )
  end

  def test_basic_pddl_parsing
    parser_tests(
    # Files
      './examples/basic_pddl/basic.pddl',
      './examples/basic_pddl/pb1.pddl',
      # Parser
      PDDL_Parser,
      # Attributes
      :domain_name => 'basic',
      :problem_name => 'problem',
      :operators => [
        ['pickup', ['?a'], [], [['have', '?a']], [['have', '?a']], []],
        ['drop', ['?a'], [['have', '?a']], [], [], [['have', '?a']]]
      ],
      :methods => [],
      :predicates => {'have' => true},
      :state => [],
      :tasks => [],
      :goal_pos => [['have', 'banjo']],
      :goal_not => []
    )
  end
end