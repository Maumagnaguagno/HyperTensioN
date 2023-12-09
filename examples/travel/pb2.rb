require_relative 'Travel'

AT = 0
CASH = 1
STAMINA = 2
OWE = 3
DISTANCE = 4
CONNECTED = 5

plan = Travel.problem(
  # Start
  [
    [
      ['me', 'home']
    ],
    [
      ['me', '20']
    ],
    [],
    [],
    [
      ['home', 'park', '8'],
      ['home', 'friend', '10'],
      ['park', 'home', '8'],
      ['park', 'friend', '2'],
      ['friend', 'home', '10'],
      ['friend', 'park', '2']
    ],
    [
      ['home', 'park'],
      ['park', 'home'],
      ['home', 'friend'],
      ['friend', 'home'],
      ['friend', 'park'],
      ['park', 'friend']
    ]
  ],
  # Tasks
  [
    [:travel, 'me', 'friend']
  ],
  # Debug
  ARGV[0] == 'debug'
)

# Test
abort('Test failed') if plan != [[:walk, 'me', 'home', 'friend']]