require './Hypertension_simple'

#-----------------------------------------------
# State Valuation
#-----------------------------------------------

def Hypertension_simple.state_valuation(state)
  case state['id']
  when 'S1' then 10
  when 'S2' then 20
  when 'S3' then 30
  when 'S4' then 40
  when 'S5' then 50
  when 'S6' then 60
  else puts "Unknown state #{state['id']}"
  end
end

#-----------------------------------------------
# Definitions
#-----------------------------------------------

def taxi_rate(dist)
  dist * 0.5 + 1.5
end

#-----------------------------------------------
# Operators
#-----------------------------------------------

def walk(state, a, x, y)
  if x != y and state['location'][a] == x
    state['location'][a] = y
    state['id'] = 'S2'
    state
  end
end

# This method can operate in both modes
# Deterministic mode
def call_taxi(state, a, x)
  state['location']['taxi'] = x
  state
end

# Probabilistic mode
def call_taxi_sucess(state, a, x)
  state['location']['taxi'] = x
  state['id'] = 'S3'
  state
end

# Probabilistic mode
def call_taxi_fail(state, a, x)
  state['location']['taxi'] = x
  state['id'] = 'S4'
  state
end

def ride_taxi(state, a, x, y)
  if x != y and state['location']['taxi'] == x and state['location'][a] == x
    state['location']['taxi'] = y
    state['location'][a] = y
    state['owe'][a] = taxi_rate(state['distance'][x][y])
    state['id'] = 'S5'
    state
  end
end

def pay_driver(state, a)
  if state['cash'][a] >= state['owe'][a]
    state['cash'][a] -= state['owe'][a]
    state['owe'][a] = 0
    state['id'] = 'S6'
    state
  end
end

def stay(state)
  state
end

#-----------------------------------------------
# Methods
#-----------------------------------------------

def stay_here(state, a, x, y)
  [['stay']] if x == y
end

def travel_by_foot(state, a, x, y)
  [['walk',a,x,y]] if x != y and (state['distance'][x][y] <= 2 or state['cash'][a] < taxi_rate(state['distance'][x][y]))
end

def travel_by_taxi(state, a, x, y)
  [['call_taxi',a,x], ['ride_taxi',a,x,y], ['pay_driver',a]] if x != y and state['cash'][a] >= taxi_rate(state['distance'][x][y])
end

#-----------------------------------------------
# Actions
#-----------------------------------------------

DETERMINISTIC_ACTIONS = {
  # Operators
  'stay' => true,
  'walk' => true,
  'call_taxi' => true,
  'ride_taxi' => true,
  'pay_driver' => true,
  # Methods
  'travel' => [
    'stay_here',
    'travel_by_foot',
    'travel_by_taxi'
  ]
}

PROBABILISTIC_ACTIONS = {
  # Operators
  'stay' => 1,
  'walk' => 1,
  'ride_taxi' => 1,
  'pay_driver' => 1,
  'stay_here' => 1,
  # Probabilistic operators
  'call_taxi' => {
    'call_taxi_sucess' => 0.8,
    'call_taxi_fail' => 0.2
  },
  # Methods
  'travel' => [
    'stay_here',
    'travel_by_foot',
    'travel_by_taxi'
  ]
}

#-----------------------------------------------
# Start
#-----------------------------------------------

START = {
  'id' => 'S1',
  'location' => {'me' => 'home'},
  'cash' => {'me' => 20},
  'owe' => {'me' => 0},
  'distance' => {
    'home'   => {'home' =>  0, 'park' => 8, 'friend' => 10},
    'park'   => {'home' =>  8, 'park' => 0, 'friend' =>  2},
    'friend' => {'home' => 10, 'park' => 2, 'friend' =>  0}
  }
}

#-----------------------------------------------
# Tasks
#-----------------------------------------------

TASKS = [
  [['travel','me','home','park']],
  [['travel','me','home','friend']],
  [['travel','me','home','home']],
  [['travel','me','home','friend'], ['travel','me','friend','park']]
]

#-----------------------------------------------
# Planning
#-----------------------------------------------

def planning(mode)
  puts '=' * 60, "#{mode ? 'Deterministic' : 'Probabilistic'} mode", '=' * 60
  TASKS.each {|task|
    puts '-' * 50
    t = Time.now.to_f
    puts "Goal: #{task.map {|i| "#{i.first}(#{i.drop(1).join(', ')})"}.join(' & ')}"
    if mode
      plan = Hypertension_simple.deterministic_planning(START, DETERMINISTIC_ACTIONS, task)
    else
      plan = Hypertension_simple.probabilistic_planning(START, PROBABILISTIC_ACTIONS, task)
    end
    if plan
      puts "Time: #{Time.now.to_f - t}s"
      if mode
        Hypertension_simple.print_deterministic_plan(plan)
      else
        Hypertension_simple.print_probabilistic_plan(plan)
      end
    else
      puts 'Planning failed'
    end
  }
end

#-----------------------------------------------
# Main
#-----------------------------------------------

begin
  case ARGV[0]
  when 'deterministic'
    planning(true)
  when 'probabilistic'
    planning(false)
  else
    planning(true)
    planning(false)
  end
rescue Interrupt
  puts 'Interrupted'
rescue
  puts $!, $@
  STDIN.gets
end