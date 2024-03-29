require './tests/hypest'

class Rescue < Test::Unit::TestCase
  include Hypest

  STATE = {
    'robot' => [['robby']],
    'hallway' => [['left'], ['middle'], ['right']],
    'location' => [['left'], ['middle'], ['right'], ['room1']],
    'room' => [['room1']],
    'beacon' => [['beacon1']],
    'at' => [['robby', 'left']],
    'in' => [['beacon1', 'room1']],
    'connected' => [
      ['middle', 'room1'],
      ['room1', 'middle'],
      ['left', 'middle'],
      ['middle', 'left'],
      ['middle', 'right'],
      ['right', 'middle']
    ]
  }

  def operators(typed = false)
    [
      ['enter', ['?bot', '?source', '?destination'],
        # Preconditions
        [
          ['robot', '?bot'],
          ['hallway', '?source'],
          ['room', '?destination'],
          ['at', '?bot', '?source'],
          [typed ? 'connected_hallway_room' : 'connected', '?source', '?destination']
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
          [typed ? 'connected_room_hallway' : 'connected', '?source', '?destination']
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
          [typed ? 'connected_hallway_hallway' : 'connected', '?source', '?destination']
        ],
        [['at', '?bot', '?destination']],
        # Effects
        [['at', '?bot', '?destination']],
        [['at', '?bot', '?source']]
      ],
      ['report', ['?bot', '?source', '?beacon'],
        # Preconditions
        [
          ['robot', '?bot'],
          ['location', '?source'],
          ['beacon', '?beacon'],
          ['at', '?bot', '?source'],
          ['in', '?beacon', '?source']
        ],
        [['reported', '?bot', '?beacon']],
        # Effects
        [['reported', '?bot', '?beacon']],
        []
      ]
    ]
  end

  def test_robby_pb1_pddl_parsing
    parser_tests(
      # Files
      'examples/robby/robby.pddl',
      'examples/robby/pb1.pddl',
      # Parser and extensions
      PDDL_Parser, [],
      # Attributes
      :domain_name => 'robby',
      :problem_name => 'pb1',
      :operators => operators,
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
      :state => STATE,
      :tasks => [],
      :goal_pos => [['reported', 'robby', 'beacon1'], ['at', 'robby', 'right']],
      :goal_not => [],
      :objects => ['robby', 'left', 'middle', 'right', 'room1', 'beacon1'],
      :requirements => [':strips', ':typing', ':negative-preconditions']
    )
  end

  def test_robby_pb1_pddl_parsing_with_typredicate
    parser_tests(
      # Files
      'examples/robby/robby.pddl',
      'examples/robby/pb1.pddl',
      # Parser and extensions
      PDDL_Parser, ['typredicate'],
      # Attributes
      :domain_name => 'robby',
      :problem_name => 'pb1',
      :operators => operators(true),
      :methods => [],
      :predicates => {
        'robot' => false,
        'hallway' => false,
        'location' => false,
        'room' => false,
        'beacon' => false,
        'at' => true,
        'in' => false,
        'connected_hallway_room' => false,
        'connected_room_hallway' => false,
        'connected_hallway_hallway' => false,
        'reported' => true
      },
      :state => STATE.merge({
        'connected_hallway_room' => [['middle', 'room1']],
        'connected_room_hallway' => [['room1', 'middle']],
        'connected_hallway_hallway' => [['left', 'middle'], ['middle', 'left'], ['middle', 'right'], ['right', 'middle']]
      }),
      :tasks => [],
      :goal_pos => [['reported', 'robby', 'beacon1'], ['at', 'robby', 'right']],
      :goal_not => [],
      :objects => ['robby', 'left', 'middle', 'right', 'room1', 'beacon1'],
      :requirements => [':strips', ':typing', ':negative-preconditions']
    )
  end

  def test_robby_pb1_pddl_parsing_with_patterns_compile_to_jshop
    compiler_tests(
      # Files
      'examples/robby/robby.pddl',
      'examples/robby/pb1.pddl',
      # Extensions and output
      ['patterns'], 'jshop',
      # Domain
"; Generated by Hype
(defdomain robby (

  ;------------------------------
  ; Operators
  ;------------------------------

  (:operator (!enter ?bot ?source ?destination)
    (
      (robot ?bot)
      (hallway ?source)
      (room ?destination)
      (at ?bot ?source)
      (connected ?source ?destination)
      (not (at ?bot ?destination))
    )
    (
      (at ?bot ?source)
    )
    (
      (at ?bot ?destination)
    )
  )

  (:operator (!exit ?bot ?source ?destination)
    (
      (robot ?bot)
      (room ?source)
      (hallway ?destination)
      (at ?bot ?source)
      (connected ?source ?destination)
      (not (at ?bot ?destination))
    )
    (
      (at ?bot ?source)
    )
    (
      (at ?bot ?destination)
    )
  )

  (:operator (!move ?bot ?source ?destination)
    (
      (robot ?bot)
      (hallway ?source)
      (hallway ?destination)
      (at ?bot ?source)
      (connected ?source ?destination)
      (not (at ?bot ?destination))
    )
    (
      (at ?bot ?source)
    )
    (
      (at ?bot ?destination)
    )
  )

  (:operator (!report ?bot ?source ?beacon)
    (
      (robot ?bot)
      (location ?source)
      (beacon ?beacon)
      (at ?bot ?source)
      (in ?beacon ?source)
      (not (reported ?bot ?beacon))
    )
    ()
    (
      (reported ?bot ?beacon)
    )
  )

  (:operator (!!#{Patterns::VISIT}_at ?bot ?source)
    ()
    ()
    (
      (visited_at ?bot ?source)
    )
  )

  (:operator (!!un#{Patterns::VISIT}_at ?bot ?source)
    ()
    (
      (visited_at ?bot ?source)
    )
    ()
  )

  (:operator (!!goal)
    (
      (reported robby beacon1)
      (at robby right)
    )
    ()
    ()
  )

  ;------------------------------
  ; Methods
  ;------------------------------

  (:method (swap_at_until_at ?bot ?destination)
    base
    (
      (at ?bot ?destination)
    )
    ()
  )

  (:method (swap_at_until_at ?bot ?destination)
    using_enter
    (
      (at ?bot ?current)
      (connected ?current ?intermediate)
      (not (at ?bot ?destination))
      (not (visited_at ?bot ?intermediate))
    )
    (
      (!enter ?bot ?current ?intermediate)
      (!!#{Patterns::VISIT}_at ?bot ?current)
      (swap_at_until_at ?bot ?destination)
      (!!un#{Patterns::VISIT}_at ?bot ?current)
    )
  )

  (:method (swap_at_until_at ?bot ?destination)
    using_exit
    (
      (at ?bot ?current)
      (connected ?current ?intermediate)
      (not (at ?bot ?destination))
      (not (visited_at ?bot ?intermediate))
    )
    (
      (!exit ?bot ?current ?intermediate)
      (!!#{Patterns::VISIT}_at ?bot ?current)
      (swap_at_until_at ?bot ?destination)
      (!!un#{Patterns::VISIT}_at ?bot ?current)
    )
  )

  (:method (swap_at_until_at ?bot ?destination)
    using_move
    (
      (at ?bot ?current)
      (connected ?current ?intermediate)
      (not (at ?bot ?destination))
      (not (visited_at ?bot ?intermediate))
    )
    (
      (!move ?bot ?current ?intermediate)
      (!!#{Patterns::VISIT}_at ?bot ?current)
      (swap_at_until_at ?bot ?destination)
      (!!un#{Patterns::VISIT}_at ?bot ?current)
    )
  )

  (:method (dependency_swap_at_until_at_before_report_for_reported ?bot ?source ?beacon)
    goal-satisfied
    (
      (reported ?bot ?beacon)
    )
    ()
  )

  (:method (dependency_swap_at_until_at_before_report_for_reported ?bot ?source ?beacon)
    unsatisfied
    (
      (robot ?bot)
      (location ?source)
      (beacon ?beacon)
      (in ?beacon ?source)
      (not (at ?bot ?source))
    )
    (
      (swap_at_until_at ?bot ?source)
      (!report ?bot ?source ?beacon)
    )
  )

  (:method (unify_source_before_dependency_swap_at_until_at_before_report_for_reported ?bot ?beacon)
    source
    (
      (robot ?bot)
      (location ?source)
      (beacon ?beacon)
      (in ?beacon ?source)
    )
    (
      (dependency_swap_at_until_at_before_report_for_reported ?bot ?source ?beacon)
    )
  )
))",
      # Problem
'; Generated by Hype
(defproblem pb1 robby

  ;------------------------------
  ; Start
  ;------------------------------

  (
    (robot robby)
    (hallway left)
    (hallway middle)
    (hallway right)
    (location left)
    (location middle)
    (location right)
    (location room1)
    (room room1)
    (beacon beacon1)
    (at robby left)
    (in beacon1 room1)
    (connected middle room1)
    (connected room1 middle)
    (connected left middle)
    (connected middle left)
    (connected middle right)
    (connected right middle)
  )

  ;------------------------------
  ; Tasks
  ;------------------------------

  (:unordered
    (unify_source_before_dependency_swap_at_until_at_before_report_for_reported robby beacon1)
    (swap_at_until_at robby right)
    (!!goal)
  )
)'
    )
  end
end