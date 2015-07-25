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