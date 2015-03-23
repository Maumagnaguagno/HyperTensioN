require './goldminer.jshop'

# Objects
ag1 = 'ag1'
p0_0 = 'p0_0'
p1_0 = 'p1_0'
p2_0 = 'p2_0'
p3_0 = 'p3_0'
p4_0 = 'p4_0'

Goldminer.problem(
  # Start
  {
    'at' => [
      [ag1, p0_0]
    ],
    'adjacent' => [
      [p0_0, p1_0],
      [p1_0, p2_0],
      [p2_0, p3_0],
      [p3_0, p4_0],
      [p4_0, p3_0],
      [p3_0, p2_0],
      [p2_0, p1_0],
      [p1_0, p0_0]
    ],
    'blocked' => [],
    'on' => [],
    'has' => [],
    'visited' => [],
    'dibs' => [],
    'next' => [],
    'duty' => [],
    'rail' => [],
    'deposit' => []
  },
  # Tasks
  [
    ['travel', ag1, p4_0]
  ]
)