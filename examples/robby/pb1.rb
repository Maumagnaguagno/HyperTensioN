require_relative 'Robby'

# Predicates
AT = 0
IN = 1
CONNECTED = 2
ROBOT = 3
OBJECT = 4
LOCATION = 5
HALLWAY = 6
ROOM = 7
BEACON = 8
REPORTED = 9

# Objects
robby = 'robby'
left = 'left'
middle = 'middle'
right = 'right'
room1 = 'room1'
beacon1 = 'beacon1'

plan = Robby.problem(
  # Start
  [
    [
      [robby, left]
    ],
    [
      [beacon1, room1]
    ],
    [
      [middle, room1],
      [room1, middle],
      [left, middle],
      [middle, left],
      [middle, right],
      [right, middle]
    ],
    [
      [robby]
    ],
    [
      [robby],
      [beacon1]
    ],
    [
      [left],
      [middle],
      [right],
      [room1]
    ],
    [
      [left],
      [middle],
      [right]
    ],
    [
      [room1]
    ],
    [
      [beacon1]
    ],
    []
  ],
  # Tasks
  [
    [:swap_at, robby, room1],
    [:report, robby, room1, beacon1],
    [:swap_at, robby, right]
  ],
  # Debug
  ARGV.first == 'debug'
)

# Test
abort('Test failed') if plan != [
  [:move, robby, left, middle],
  [:enter, robby, middle, room1],
  [:report, robby, room1, beacon1],
  [:exit, robby, room1, middle],
  [:move, robby, middle, right]
]