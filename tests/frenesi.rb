require 'test/unit'
require './Hype'

class Frenesi < Test::Unit::TestCase

  def parser_tests(domain, problem, expected_parser, expected)
    Hype.parse(domain, problem)
    parser = Hype.parser
    assert_equal(expected_parser, parser)
    expected.each {|att,value| assert_equal(value, parser.send(att))}
  end

  def compiler_tests(domain, problem, type, expected_domain, expected_problem)
    domain_type = "#{domain}.#{type}"
    problem_type = "#{problem}.#{type}"
    File.delete(domain_type) if File.exist?(domain_type)
    File.delete(problem_type) if File.exist?(problem_type)
    Hype.parse(domain, problem)
    Hype.compile(domain, problem, type)
    assert_equal(true, File.exist?(domain_type))
    assert_equal(true, File.exist?(problem_type))
    domain_generated = IO.read(domain_type)
    problem_generated = IO.read(problem_type)
    assert_equal(expected_domain, domain_generated)
    assert_equal(expected_problem, problem_generated)
    File.delete(domain_type, problem_type)
  end

  #-----------------------------------------------
  # Extension
  #-----------------------------------------------

  def test_different_extensions
    assert_raises(RuntimeError) {Hype.parse('a.pddl','b.jshop')}
  end

  def test_unknown_extension
    assert_raises(RuntimeError) {Hype.parse('a.blob','b.blob')}
  end

  #-----------------------------------------------
  # Parsing
  #-----------------------------------------------

  def test_basic_jshop_parsing
    parser_tests(
      # Files
      './examples/basic_jshop/basic.jshop',
      './examples/basic_jshop/pb1.jshop',
      # Parser
      JSHOP_Parser,
      # Attributes
      :domain_name => 'basic',
      :problem_name => 'problem',
      :operators => [
        ['pickup', ['?a'],
          # Preconditions
          [],
          [],
          # Effects
          [['have', '?a']],
          []
        ],
        ['drop', ['?a'],
          # Preconditions
          [['have', '?a']],
          [],
          # Effects
          [],
          [['have', '?a']]
        ]
      ],
      :methods => [
        ['swap', ['?x', '?y'],
          ['swap_0',
            # Preconditions
            [],
            [['have', '?x']],
            # Effects
            [['have', '?y']],
            [['drop', '?x'], ['pickup', '?y']]
          ],
          ['swap_1',
            # Preconditions
            [],
            [['have', '?y']],
            # Effects
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
        ['pickup', ['?a'],
          # Preconditions
          [],
          [['have', '?a']],
          # Effects
          [['have', '?a']],
          []
        ],
        ['drop', ['?a'],
          # Preconditions
          [['have', '?a']],
          [],
          # Effects
          [],
          [['have', '?a']]
        ]
      ],
      :methods => [],
      :predicates => {'have' => true},
      :state => [],
      :tasks => [],
      :goal_pos => [['have', 'banjo']],
      :goal_not => []
    )
  end

  def test_dependency_pddl_parsing
    parser_tests(
      # Files
      './examples/dependency_pddl/dependency.pddl',
      './examples/dependency_pddl/pb1.pddl',
      # Parser
      PDDL_Parser,
      # Attributes
      :domain_name => 'dependency',
      :problem_name => 'problem',
      :operators => [
        ['work', ['?a'],
          # Preconditions
          [['agent', '?a']],
          [['got_money', '?a']],
          # Effects
          [['got_money', '?a']],
          [['happy', '?a']]
        ],
        ['buy', ['?a', '?x'],
          # Preconditions
          [['agent', '?a'], ['object', '?x']],
          [['have', '?a', '?x']],
          # Effects
          [['have', '?a', '?x']],
          []
        ],
        ['give', ['?a', '?b', '?x'],
          # Preconditions
          [['agent', '?a'], ['agent', '?b'], ['object', '?x'], ['have', '?a', '?x']],
          [['have', '?b', '?x']],
          # Effects
          [['have', '?b', '?x'], ['happy', '?b']],
          [['have', '?a', '?x']]
        ]
      ],
      :methods => [],
      :predicates => {
        'agent' => false,
        'object' => false,
        'have' => true,
        'got_money' => true,
        'happy' => true
      },
      :state => [
        ['agent', 'ana'],
        ['agent', 'bob'],
        ['object', 'gift'],
        ['have', 'ana', 'gift']
      ],
      :tasks => [],
      :goal_pos => [['happy', 'bob']],
      :goal_not => []
    )
  end

  def test_robby_pddl_parsing
    parser_tests(
      # Files
      './examples/robby_pddl/robby.pddl',
      './examples/robby_pddl/pb1.pddl',
      # Parser
      PDDL_Parser,
      # Attributes
      :domain_name => 'robby',
      :problem_name => 'pb1',
      :operators => [
        ['enter', ['?bot', '?source', '?destination'],
          # Preconditions
          [
            ['robot', '?bot'],
            ['hallway', '?source'],
            ['room', '?destination'],
            ['at', '?bot', '?source'],
            ['connected', '?source', '?destination']
          ],
          [['at', '?bot', '?destination']],
          # Effects
          [['at', '?bot', '?destination']],
          [['at', '?bot', '?source']]
        ],
        ['exit', ['?bot', '?source', '?destination'],
          # Preconditions
          [
            ['robot', '?bot'],
            ['room', '?source'],
            ['hallway', '?destination'],
            ['at', '?bot', '?source'],
            ['connected', '?source', '?destination']
          ],
          [['at', '?bot', '?destination']],
          # Effects
          [['at', '?bot', '?destination']],
          [['at', '?bot', '?source']]
        ],
        ['move', ['?bot', '?source', '?destination'],
          # Preconditions
          [
            ['robot', '?bot'],
            ['hallway', '?source'],
            ['hallway', '?destination'],
            ['at', '?bot', '?source'],
            ['connected', '?source', '?destination']
          ],
          [['at', '?bot', '?destination']],
          # Effects
          [['at', '?bot', '?destination']],
          [['at', '?bot', '?source']]
        ],
        ['report', ['?bot', '?source', '?thing'],
          # Preconditions
          [
            ['robot', '?bot'],
            ['location', '?source'],
            ['beacon', '?thing'],
            ['at', '?bot', '?source'],
            ['in', '?thing', '?source']
          ],
          [['reported', '?bot', '?thing']],
          # Effects
          [['reported', '?bot', '?thing']],
          []
        ]
      ],
      :methods => [],
      :predicates => {
        'robot' => false,
        'beacon' => false,
        'room' => false,
        'hallway' => false,
        'location' => false,
        'at' => true,
        'in' => false,
        'connected' => false,
        'reported' => true
      },
      :state => [
        ['robot', 'robby'],
        ['object', 'robby'],
        ['hallway', 'left'],
        ['location', 'left'],
        ['object', 'left'],
        ['hallway', 'middle'],
        ['location', 'middle'],
        ['object', 'middle'],
        ['hallway', 'right'],
        ['location', 'right'],
        ['object', 'right'],
        ['room', 'room1'],
        ['location', 'room1'],
        ['object', 'room1'],
        ['beacon', 'beacon1'],
        ['object', 'beacon1'],
        ['at', 'robby', 'left'],
        ['in', 'beacon1', 'room1'],
        ['connected', 'middle', 'room1'],
        ['connected', 'room1', 'middle'],
        ['connected', 'left', 'middle'],
        ['connected', 'middle', 'left'],
        ['connected', 'middle', 'right'],
        ['connected', 'right', 'middle']
      ],
      :tasks => [],
      :goal_pos => [['reported', 'robby', 'beacon1'], ['at', 'robby', 'right']],
      :goal_not => []
    )
  end

  #-----------------------------------------------
  # Compilation
  #-----------------------------------------------

  def test_basic_jshop_compile_to_pddl
    compiler_tests(
      # Files
      './examples/basic_jshop/basic.jshop',
      './examples/basic_jshop/pb1.jshop',
      # Type
      'pddl',
      # Domain
'; Generated by Hype
(define (domain basic)
  (:requirements :strips)

  (:predicates
    (have ?a)
  )

  (:action pickup
    :parameters (?a)
    :precondition
      (and
      )
    :effect
      (and
        (have ?a)
      )
  )

  (:action drop
    :parameters (?a)
    :precondition
      (and
        (have ?a)
      )
    :effect
      (and
        (not (have ?a))
      )
  )
)',
      # Problem
'; Generated by Hype
(define (problem problem)
  (:domain basic)
  (:requirements :strips)
  (:objects
    kiwi banjo
  )
  (:init
    (have kiwi)
  )
  (:goal
    (and
    )
  )
)'
    )
  end
end