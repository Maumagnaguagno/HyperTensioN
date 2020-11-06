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
      ['me', 'home'],
      ['taxi', 'park']
    ],
    [
      ['me', '20']
    ],
    [
      ['me', '2']
    ],
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
    ['travel', 'me', 'friend'],
    ['travel', 'me', 'park']
  ],
  # Debug
  ARGV.first == 'debug'
)

# Test
abort('Test failed') if plan != [
  ['call_taxi', 'park', 'home'],
  ['ride_taxi', 'me', 'home', 'friend', '6.5'],
  ['pay_driver', 'me', '20', '6.5'],
  ['call_taxi', 'friend', 'home'],
  ['ride_taxi', 'me', 'home', 'park', '5.5'],
  ['pay_driver', 'me', '13.5', '5.5']
]