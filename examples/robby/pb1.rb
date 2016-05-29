require_relative 'Robby'

# Objects
robby = 'robby'
left = 'left'
middle = 'middle'
right = 'right'
room1 = 'room1'
beacon1 = 'beacon1'

plan = Robby.problem(
  # Start
  {
    'at' => [
      [robby, left]
    ],
    'in' => [
      [beacon1, room1]
    ],
    'connected' => [
      [middle, room1],
      [room1, middle],
      [left, middle],
      [middle, left],
      [middle, right],
      [right, middle]
    ],
    'robot' => [
      [robby]
    ],
    'object' => [
      [robby],
      [beacon1]
    ],
    'location' => [
      [left],
      [middle],
      [right],
      [room1]
    ],
    'hallway' => [
      [left],
      [middle],
      [right]
    ],
    'room' => [
      [room1]
    ],
    'beacon' => [
      [beacon1]
    ],
    'reported' => []
  },
  # Tasks
  [
    ['swap_at', robby, room1],
    ['report', robby, room1, beacon1],
    ['swap_at', robby, right]
  ],
  # Debug
  ARGV.first == '-d'
)

# Test
abort('Test failed') if plan != [
  ['move', robby, left, middle],
  ['enter', robby, middle, room1],
  ['report', robby, room1, beacon1],
  ['exit', robby, room1, middle],
  ['move', robby, middle, right]
]