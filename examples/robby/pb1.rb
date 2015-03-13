require './Robby'

# Objects
robby = 'robby'
left = 'left'
middle = 'middle'
right = 'right'
room1 = 'room1'
beacon1 = 'beacon1'

Robby.problem(
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
    'object'=> [
      [robby],
      [beacon1]
    ],
    'location' => [
      [left],
      [middle],
      [right],
      [room1],
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
  true
)