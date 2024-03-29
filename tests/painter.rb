require './tests/hypest'

class Painter < Test::Unit::TestCase
  include Hypest

  def paint_operator(direction)
    ["paint-#{direction}", ['?r', '?y', '?x', '?c'],
      # Preconditions
      [
        ['robot', '?r'],
        ['tile', '?y'],
        ['tile', '?x'],
        ['color', '?c'],
        ['robot-has', '?r', '?c'],
        ['robot-at', '?r', '?x'],
        [direction, '?y', '?x'],
        ['clear', '?y']
      ],
      [],
      # Effects
      [['painted', '?y', '?c']],
      [['clear', '?y']]
    ]
  end

  def move_operator(direction)
    [direction, ['?r', '?x', '?y'],
      # Preconditions
      [
        ['robot', '?r'],
        ['tile', '?x'],
        ['tile', '?y'],
        ['robot-at', '?r', '?x'],
        [direction, '?y', '?x'],
        ['clear', '?y']
      ],
      [],
      # Effects
      [
        ['robot-at', '?r', '?y'],
        ['clear', '?x']
      ],
      [
        ['robot-at', '?r', '?x'],
        ['clear', '?y']
      ]
    ]
  end

  def test_floortile_pb1_pddl_parsing
    parser_tests(
      # Files
      'examples/floortile/floortile.pddl',
      'examples/floortile/pb1.pddl',
      # Parser and extensions
      PDDL_Parser, [],
      # Attributes
      :domain_name => 'floortile',
      :problem_name => 'pb1',
      :operators => [
        ['change-color', ['?r', '?c', '?c2'],
          # Preconditions
          [
            ['robot', '?r'],
            ['color', '?c'],
            ['color', '?c2'],
            ['robot-has', '?r', '?c'],
            ['available-color', '?c2']
          ],
          [],
          # Effects
          [['robot-has', '?r', '?c2']],
          [['robot-has', '?r', '?c']]
        ],
        paint_operator('up'),
        paint_operator('down'),
        move_operator('up'),
        move_operator('down'),
        move_operator('right'),
        move_operator('left')
      ],
      :methods => [],
      :predicates => {
        'robot' => false,
        'tile' => false,
        'color' => false,
        'robot-at' => true,
        'up' => false,
        'down' => false,
        'right' => false,
        'left' => false,
        'clear' => true,
        'painted' => true,
        'robot-has' => true,
        'available-color' => false,
      },
      :state => {
        'tile' => [['top_left'], ['top_right'], ['bottom_left'], ['bottom_right']],
        'robot' => [['robot1']],
        'color' => [['white'], ['black']],
        'robot-at' => [['robot1', 'top_right']],
        'clear' => [['top_left'], ['bottom_right'], ['bottom_left']],
        'robot-has' => [['robot1', 'white']],
        'available-color' => [['white'], ['black']],
        'up' => [['top_right', 'bottom_right'], ['top_left', 'bottom_left']],
        'down' => [['bottom_right', 'top_right'], ['bottom_left', 'top_left']],
        'left' => [['top_right', 'top_left'], ['bottom_right', 'bottom_left']],
        'right' => [['top_left', 'top_right'], ['bottom_left', 'bottom_right']]
      },
      :tasks => [],
      :goal_pos => [
        ['painted', 'top_right', 'black'],
        ['painted', 'bottom_left', 'white']
      ],
      :goal_not => [],
      :objects => ['top_left', 'top_right', 'bottom_left', 'bottom_right', 'robot1', 'white', 'black'],
      :requirements => [':strips', ':typing']
    )
  end

  def test_painter_pb1_pddl_parsing_with_patterns_compile_to_jshop
    compiler_tests(
      # Files
      'examples/floortile/floortile.pddl',
      'examples/floortile/pb1.pddl',
      # Extensions and output
      ['patterns'], 'jshop',
      # Domain
"; Generated by Hype
(defdomain floortile (

  ;------------------------------
  ; Operators
  ;------------------------------

  (:operator (!change-color ?r ?c ?c2)
    (
      (robot ?r)
      (color ?c)
      (color ?c2)
      (robot-has ?r ?c)
      (available-color ?c2)
    )
    (
      (robot-has ?r ?c)
    )
    (
      (robot-has ?r ?c2)
    )
  )

  (:operator (!paint-up ?r ?y ?x ?c)
    (
      (robot ?r)
      (tile ?y)
      (tile ?x)
      (color ?c)
      (robot-has ?r ?c)
      (robot-at ?r ?x)
      (up ?y ?x)
      (clear ?y)
    )
    (
      (clear ?y)
    )
    (
      (painted ?y ?c)
    )
  )

  (:operator (!paint-down ?r ?y ?x ?c)
    (
      (robot ?r)
      (tile ?y)
      (tile ?x)
      (color ?c)
      (robot-has ?r ?c)
      (robot-at ?r ?x)
      (down ?y ?x)
      (clear ?y)
    )
    (
      (clear ?y)
    )
    (
      (painted ?y ?c)
    )
  )

  (:operator (!up ?r ?x ?y)
    (
      (robot ?r)
      (tile ?x)
      (tile ?y)
      (robot-at ?r ?x)
      (up ?y ?x)
      (clear ?y)
    )
    (
      (robot-at ?r ?x)
      (clear ?y)
    )
    (
      (robot-at ?r ?y)
      (clear ?x)
    )
  )

  (:operator (!down ?r ?x ?y)
    (
      (robot ?r)
      (tile ?x)
      (tile ?y)
      (robot-at ?r ?x)
      (down ?y ?x)
      (clear ?y)
    )
    (
      (robot-at ?r ?x)
      (clear ?y)
    )
    (
      (robot-at ?r ?y)
      (clear ?x)
    )
  )

  (:operator (!right ?r ?x ?y)
    (
      (robot ?r)
      (tile ?x)
      (tile ?y)
      (robot-at ?r ?x)
      (right ?y ?x)
      (clear ?y)
    )
    (
      (robot-at ?r ?x)
      (clear ?y)
    )
    (
      (robot-at ?r ?y)
      (clear ?x)
    )
  )

  (:operator (!left ?r ?x ?y)
    (
      (robot ?r)
      (tile ?x)
      (tile ?y)
      (robot-at ?r ?x)
      (left ?y ?x)
      (clear ?y)
    )
    (
      (robot-at ?r ?x)
      (clear ?y)
    )
    (
      (robot-at ?r ?y)
      (clear ?x)
    )
  )

  (:operator (!!#{Patterns::VISIT}_robot-at ?r ?x)
    ()
    ()
    (
      (visited_robot-at ?r ?x)
    )
  )

  (:operator (!!un#{Patterns::VISIT}_robot-at ?r ?x)
    ()
    (
      (visited_robot-at ?r ?x)
    )
    ()
  )

  (:operator (!!#{Patterns::VISIT}_clear ?y)
    ()
    ()
    (
      (visited_clear ?y)
    )
  )

  (:operator (!!un#{Patterns::VISIT}_clear ?y)
    ()
    (
      (visited_clear ?y)
    )
    ()
  )

  (:operator (!!goal)
    (
      (painted top_right black)
      (painted bottom_left white)
    )
    ()
    ()
  )

  ;------------------------------
  ; Methods
  ;------------------------------

  (:method (swap_robot-at_until_robot-at ?r ?y)
    base
    (
      (robot-at ?r ?y)
    )
    ()
  )

  (:method (swap_robot-at_until_robot-at ?r ?y)
    using_up
    (
      (robot-at ?r ?current)
      (up ?intermediate ?current)
      (not (robot-at ?r ?y))
      (not (visited_robot-at ?r ?intermediate))
    )
    (
      (!up ?r ?current ?intermediate)
      (!!#{Patterns::VISIT}_robot-at ?r ?current)
      (swap_robot-at_until_robot-at ?r ?y)
      (!!un#{Patterns::VISIT}_robot-at ?r ?current)
    )
  )

  (:method (swap_robot-at_until_robot-at ?r ?y)
    using_down
    (
      (robot-at ?r ?current)
      (down ?intermediate ?current)
      (not (robot-at ?r ?y))
      (not (visited_robot-at ?r ?intermediate))
    )
    (
      (!down ?r ?current ?intermediate)
      (!!#{Patterns::VISIT}_robot-at ?r ?current)
      (swap_robot-at_until_robot-at ?r ?y)
      (!!un#{Patterns::VISIT}_robot-at ?r ?current)
    )
  )

  (:method (swap_robot-at_until_robot-at ?r ?y)
    using_right
    (
      (robot-at ?r ?current)
      (right ?intermediate ?current)
      (not (robot-at ?r ?y))
      (not (visited_robot-at ?r ?intermediate))
    )
    (
      (!right ?r ?current ?intermediate)
      (!!#{Patterns::VISIT}_robot-at ?r ?current)
      (swap_robot-at_until_robot-at ?r ?y)
      (!!un#{Patterns::VISIT}_robot-at ?r ?current)
    )
  )

  (:method (swap_robot-at_until_robot-at ?r ?y)
    using_left
    (
      (robot-at ?r ?current)
      (left ?intermediate ?current)
      (not (robot-at ?r ?y))
      (not (visited_robot-at ?r ?intermediate))
    )
    (
      (!left ?r ?current ?intermediate)
      (!!#{Patterns::VISIT}_robot-at ?r ?current)
      (swap_robot-at_until_robot-at ?r ?y)
      (!!un#{Patterns::VISIT}_robot-at ?r ?current)
    )
  )

  (:method (swap_robot-at_until_clear ?r ?y)
    base
    (
      (up ?y ?x)
      (clear ?x)
    )
    ()
  )

  (:method (swap_robot-at_until_clear ?r ?y)
    using_up
    (
      (robot-at ?r ?current)
      (up ?intermediate ?current)
      (not (robot-at ?r ?y))
      (not (visited_robot-at ?r ?intermediate))
    )
    (
      (!up ?r ?current ?intermediate)
      (!!#{Patterns::VISIT}_robot-at ?r ?current)
      (swap_robot-at_until_clear ?r ?y)
      (!!un#{Patterns::VISIT}_robot-at ?r ?current)
    )
  )

  (:method (swap_robot-at_until_clear ?r ?y)
    using_down
    (
      (robot-at ?r ?current)
      (down ?intermediate ?current)
      (not (robot-at ?r ?y))
      (not (visited_robot-at ?r ?intermediate))
    )
    (
      (!down ?r ?current ?intermediate)
      (!!#{Patterns::VISIT}_robot-at ?r ?current)
      (swap_robot-at_until_clear ?r ?y)
      (!!un#{Patterns::VISIT}_robot-at ?r ?current)
    )
  )

  (:method (swap_robot-at_until_clear ?r ?y)
    using_right
    (
      (robot-at ?r ?current)
      (right ?intermediate ?current)
      (not (robot-at ?r ?y))
      (not (visited_robot-at ?r ?intermediate))
    )
    (
      (!right ?r ?current ?intermediate)
      (!!#{Patterns::VISIT}_robot-at ?r ?current)
      (swap_robot-at_until_clear ?r ?y)
      (!!un#{Patterns::VISIT}_robot-at ?r ?current)
    )
  )

  (:method (swap_robot-at_until_clear ?r ?y)
    using_left
    (
      (robot-at ?r ?current)
      (left ?intermediate ?current)
      (not (robot-at ?r ?y))
      (not (visited_robot-at ?r ?intermediate))
    )
    (
      (!left ?r ?current ?intermediate)
      (!!#{Patterns::VISIT}_robot-at ?r ?current)
      (swap_robot-at_until_clear ?r ?y)
      (!!un#{Patterns::VISIT}_robot-at ?r ?current)
    )
  )

  (:method (swap_clear_until_robot-at ?x)
    base
    (
      (up ?y ?x)
      (robot-at ?r ?y)
    )
    ()
  )

  (:method (swap_clear_until_robot-at ?x)
    using_up
    (
      (clear ?current)
      (up ?current ?intermediate)
      (not (clear ?x))
      (not (visited_clear ?intermediate))
    )
    (
      (!up ?r ?intermediate ?current)
      (!!#{Patterns::VISIT}_clear ?current)
      (swap_clear_until_robot-at ?x)
      (!!un#{Patterns::VISIT}_clear ?current)
    )
  )

  (:method (swap_clear_until_robot-at ?x)
    using_down
    (
      (clear ?current)
      (down ?current ?intermediate)
      (not (clear ?x))
      (not (visited_clear ?intermediate))
    )
    (
      (!down ?r ?intermediate ?current)
      (!!#{Patterns::VISIT}_clear ?current)
      (swap_clear_until_robot-at ?x)
      (!!un#{Patterns::VISIT}_clear ?current)
    )
  )

  (:method (swap_clear_until_robot-at ?x)
    using_right
    (
      (clear ?current)
      (right ?current ?intermediate)
      (not (clear ?x))
      (not (visited_clear ?intermediate))
    )
    (
      (!right ?r ?intermediate ?current)
      (!!#{Patterns::VISIT}_clear ?current)
      (swap_clear_until_robot-at ?x)
      (!!un#{Patterns::VISIT}_clear ?current)
    )
  )

  (:method (swap_clear_until_robot-at ?x)
    using_left
    (
      (clear ?current)
      (left ?current ?intermediate)
      (not (clear ?x))
      (not (visited_clear ?intermediate))
    )
    (
      (!left ?r ?intermediate ?current)
      (!!#{Patterns::VISIT}_clear ?current)
      (swap_clear_until_robot-at ?x)
      (!!un#{Patterns::VISIT}_clear ?current)
    )
  )

  (:method (swap_clear_until_clear ?x)
    base
    (
      (clear ?x)
    )
    ()
  )

  (:method (swap_clear_until_clear ?x)
    using_up
    (
      (clear ?current)
      (up ?current ?intermediate)
      (not (clear ?x))
      (not (visited_clear ?intermediate))
    )
    (
      (!up ?r ?intermediate ?current)
      (!!#{Patterns::VISIT}_clear ?current)
      (swap_clear_until_clear ?x)
      (!!un#{Patterns::VISIT}_clear ?current)
    )
  )

  (:method (swap_clear_until_clear ?x)
    using_down
    (
      (clear ?current)
      (down ?current ?intermediate)
      (not (clear ?x))
      (not (visited_clear ?intermediate))
    )
    (
      (!down ?r ?intermediate ?current)
      (!!#{Patterns::VISIT}_clear ?current)
      (swap_clear_until_clear ?x)
      (!!un#{Patterns::VISIT}_clear ?current)
    )
  )

  (:method (swap_clear_until_clear ?x)
    using_right
    (
      (clear ?current)
      (right ?current ?intermediate)
      (not (clear ?x))
      (not (visited_clear ?intermediate))
    )
    (
      (!right ?r ?intermediate ?current)
      (!!#{Patterns::VISIT}_clear ?current)
      (swap_clear_until_clear ?x)
      (!!un#{Patterns::VISIT}_clear ?current)
    )
  )

  (:method (swap_clear_until_clear ?x)
    using_left
    (
      (clear ?current)
      (left ?current ?intermediate)
      (not (clear ?x))
      (not (visited_clear ?intermediate))
    )
    (
      (!left ?r ?intermediate ?current)
      (!!#{Patterns::VISIT}_clear ?current)
      (swap_clear_until_clear ?x)
      (!!un#{Patterns::VISIT}_clear ?current)
    )
  )

  (:method (dependency_change-color_before_paint-up_or_paint-down_for_painted ?r ?c ?c2 ?y ?x)
    goal-satisfied
    (
      (painted ?y ?c)
    )
    ()
  )

  (:method (dependency_change-color_before_paint-up_or_paint-down_for_painted ?r ?c ?c2 ?y ?x)
    satisfied_paint-up
    (
      (robot ?r)
      (tile ?y)
      (tile ?x)
      (color ?c)
      (up ?y ?x)
      (robot-has ?r ?c)
    )
    (
      (dependency_swap_robot-at_until_robot-at_before_paint-up_or_paint-down_for_painted ?r ?x ?y ?c)
    )
  )

  (:method (dependency_change-color_before_paint-up_or_paint-down_for_painted ?r ?c ?c2 ?y ?x)
    satisfied_paint-down
    (
      (robot ?r)
      (tile ?y)
      (tile ?x)
      (color ?c)
      (down ?y ?x)
      (robot-has ?r ?c)
    )
    (
      (dependency_swap_robot-at_until_robot-at_before_paint-up_or_paint-down_for_painted ?r ?x ?y ?c)
    )
  )

  (:method (dependency_change-color_before_paint-up_or_paint-down_for_painted ?r ?c ?c2 ?y ?x)
    unsatisfied_paint-up
    (
      (robot ?r)
      (tile ?y)
      (tile ?x)
      (color ?c)
      (up ?y ?x)
      (color ?c2)
      (available-color ?c2)
      (not (robot-has ?r ?c))
    )
    (
      (!change-color ?r ?c2 ?c)
      (dependency_swap_robot-at_until_robot-at_before_paint-up_or_paint-down_for_painted ?r ?x ?y ?c)
    )
  )

  (:method (dependency_change-color_before_paint-up_or_paint-down_for_painted ?r ?c ?c2 ?y ?x)
    unsatisfied_paint-down
    (
      (robot ?r)
      (tile ?y)
      (tile ?x)
      (color ?c)
      (down ?y ?x)
      (color ?c2)
      (available-color ?c2)
      (not (robot-has ?r ?c))
    )
    (
      (!change-color ?r ?c2 ?c)
      (dependency_swap_robot-at_until_robot-at_before_paint-up_or_paint-down_for_painted ?r ?x ?y ?c)
    )
  )

  (:method (dependency_swap_robot-at_until_robot-at_before_paint-up_or_paint-down_for_painted ?r ?x ?y ?c)
    goal-satisfied
    (
      (painted ?y ?c)
    )
    ()
  )

  (:method (dependency_swap_robot-at_until_robot-at_before_paint-up_or_paint-down_for_painted ?r ?x ?y ?c)
    unsatisfied_paint-up
    (
      (robot ?r)
      (tile ?y)
      (tile ?x)
      (color ?c)
      (up ?y ?x)
      (not (robot-at ?r ?x))
    )
    (
      (swap_robot-at_until_robot-at ?r ?x)
      (!paint-up ?r ?y ?x ?c)
    )
  )

  (:method (dependency_swap_robot-at_until_robot-at_before_paint-up_or_paint-down_for_painted ?r ?x ?y ?c)
    unsatisfied_paint-down
    (
      (robot ?r)
      (tile ?y)
      (tile ?x)
      (color ?c)
      (down ?y ?x)
      (not (robot-at ?r ?x))
    )
    (
      (swap_robot-at_until_robot-at ?r ?x)
      (!paint-down ?r ?y ?x ?c)
    )
  )

  (:method (unify_r_c2_x_before_dependency_change-color_before_paint-up_or_paint-down_for_painted ?c ?y)
    r_c2_x
    (
      (robot ?r)
      (tile ?y)
      (tile ?x)
      (color ?c)
      (color ?c2)
      (available-color ?c2)
    )
    (
      (dependency_change-color_before_paint-up_or_paint-down_for_painted ?r ?c ?c2 ?y ?x)
    )
  )
))",
      # Problem
'; Generated by Hype
(defproblem pb1 floortile

  ;------------------------------
  ; Start
  ;------------------------------

  (
    (tile top_left)
    (tile top_right)
    (tile bottom_left)
    (tile bottom_right)
    (robot robot1)
    (color white)
    (color black)
    (robot-at robot1 top_right)
    (clear top_left)
    (clear bottom_right)
    (clear bottom_left)
    (robot-has robot1 white)
    (available-color white)
    (available-color black)
    (up top_right bottom_right)
    (up top_left bottom_left)
    (down bottom_right top_right)
    (down bottom_left top_left)
    (left top_right top_left)
    (left bottom_right bottom_left)
    (right top_left top_right)
    (right bottom_left bottom_right)
  )

  ;------------------------------
  ; Tasks
  ;------------------------------

  (:unordered
    (unify_r_c2_x_before_dependency_change-color_before_paint-up_or_paint-down_for_painted black top_right)
    (unify_r_c2_x_before_dependency_change-color_before_paint-up_or_paint-down_for_painted white bottom_left)
    (!!goal)
  )
)'
    )
  end
end