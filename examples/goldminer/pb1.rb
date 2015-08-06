require File.expand_path('../Goldminer', __FILE__)

Goldminer.problem(
  # Start
  {
    'duty' => [
      ['ag1']
    ],
    'next' => [
      ['ag1', 'ag1']
    ],
    'deposit' => [
      ['p8_6']
    ],
    'on' => [
      ['g1', 'p4_0'],
      ['g2', 'p4_3'],
      ['g3', 'p5_9']
    ],
    'blocked' => [
      ['p1_1'],
      ['p2_1'],
      ['p3_1'],
      ['p4_1'],
      ['p5_1'],
      ['p6_1'],
      ['p7_1'],
      ['p8_1'],
      ['p3_6'],
      ['p6_6'],
      ['p3_7'],
      ['p6_7'],
      ['p1_8'],
      ['p2_8'],
      ['p3_8'],
      ['p6_8'],
      ['p7_8'],
      ['p8_8']
    ],
    'at' => [
      ['ag1', 'p1_6']
    ],
    'adjacent' => Goldminer.generate_grid(10,10),
    'dibs' => [],
    'have' => []
  },
  # Tasks
  [
    ['get_gold']
  ],
  # Debug
  ARGV.first == '-d'
)

# Test
expected = [
  ['move', 'ag1', 'p1_6', 'p1_5'],
  ['move', 'ag1', 'p1_5', 'p1_4'],
  ['move', 'ag1', 'p1_4', 'p1_3'],
  ['move', 'ag1', 'p1_3', 'p1_2'],
  ['move', 'ag1', 'p1_2', 'p0_2'],
  ['move', 'ag1', 'p0_2', 'p0_1'],
  ['move', 'ag1', 'p0_1', 'p0_0'],
  ['move', 'ag1', 'p0_0', 'p1_0'],
  ['move', 'ag1', 'p1_0', 'p2_0'],
  ['move', 'ag1', 'p2_0', 'p3_0'],
  ['move', 'ag1', 'p3_0', 'p4_0'],
  ['pick', 'ag1', 'g1', 'p4_0'],
  ['move', 'ag1', 'p4_0', 'p5_0'],
  ['move', 'ag1', 'p5_0', 'p6_0'],
  ['move', 'ag1', 'p6_0', 'p7_0'],
  ['move', 'ag1', 'p7_0', 'p8_0'],
  ['move', 'ag1', 'p8_0', 'p9_0'],
  ['move', 'ag1', 'p9_0', 'p9_1'],
  ['move', 'ag1', 'p9_1', 'p9_2'],
  ['move', 'ag1', 'p9_2', 'p8_2'],
  ['move', 'ag1', 'p8_2', 'p8_3'],
  ['move', 'ag1', 'p8_3', 'p8_4'],
  ['move', 'ag1', 'p8_4', 'p8_5'],
  ['move', 'ag1', 'p8_5', 'p8_6'],
  ['drop', 'ag1', 'g1', 'p8_6'],
  ['move', 'ag1', 'p8_6', 'p8_5'],
  ['move', 'ag1', 'p8_5', 'p8_4'],
  ['move', 'ag1', 'p8_4', 'p8_3'],
  ['move', 'ag1', 'p8_3', 'p7_3'],
  ['move', 'ag1', 'p7_3', 'p6_3'],
  ['move', 'ag1', 'p6_3', 'p5_3'],
  ['move', 'ag1', 'p5_3', 'p4_3'],
  ['pick', 'ag1', 'g2', 'p4_3'],
  ['move', 'ag1', 'p4_3', 'p5_3'],
  ['move', 'ag1', 'p5_3', 'p6_3'],
  ['move', 'ag1', 'p6_3', 'p7_3'],
  ['move', 'ag1', 'p7_3', 'p8_3'],
  ['move', 'ag1', 'p8_3', 'p8_4'],
  ['move', 'ag1', 'p8_4', 'p8_5'],
  ['move', 'ag1', 'p8_5', 'p8_6'],
  ['drop', 'ag1', 'g2', 'p8_6'],
  ['move', 'ag1', 'p8_6', 'p8_5'],
  ['move', 'ag1', 'p8_5', 'p7_5'],
  ['move', 'ag1', 'p7_5', 'p6_5'],
  ['move', 'ag1', 'p6_5', 'p5_5'],
  ['move', 'ag1', 'p5_5', 'p5_6'],
  ['move', 'ag1', 'p5_6', 'p5_7'],
  ['move', 'ag1', 'p5_7', 'p5_8'],
  ['move', 'ag1', 'p5_8', 'p5_9'],
  ['pick', 'ag1', 'g3', 'p5_9'],
  ['move', 'ag1', 'p5_9', 'p5_8'],
  ['move', 'ag1', 'p5_8', 'p5_7'],
  ['move', 'ag1', 'p5_7', 'p5_6'],
  ['move', 'ag1', 'p5_6', 'p5_5'],
  ['move', 'ag1', 'p5_5', 'p6_5'],
  ['move', 'ag1', 'p6_5', 'p7_5'],
  ['move', 'ag1', 'p7_5', 'p8_5'],
  ['move', 'ag1', 'p8_5', 'p8_6'],
  ['drop', 'ag1', 'g3', 'p8_6']
]
abort('Test failed') if plan != expected