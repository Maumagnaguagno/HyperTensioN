require './Hop'

def taxi_rate(dist)
  dist * 0.5 + 1.5
end

def walk(state, a, x, y)
  if state[:loc][a] == x
    state[:loc][a] = y
    state
  end
end

def call_taxi(state, a, x)
  state[:loc]['taxi'] = x
  state
end

def ride_taxi(state, a, x, y)
  if state[:loc]['taxi'] == x and state[:loc][a] == x
    state[:loc]['taxi'] = y
    state[:loc][a] = y
    state[:owe][a] = taxi_rate(state[:dist][x][y])
    state
  end
end

def pay_driver(state, a)
  if state[:cash][a] >= state[:owe][a]
    state[:cash][a] -= state[:owe][a]
    state[:owe][a] = 0
    state
  end
end

def travel_by_foot(state, a, x, y)
   [[:walk,a,x,y]] if state[:dist][x][y] <= 2
end

def travel_by_taxi(state, a, x, y)
  [[:call_taxi,a,x], [:ride_taxi,a,x,y], [:pay_driver,a]] if state[:cash][a] >= taxi_rate(state[:dist][x][y])
end

Hop.declare_operators(:walk, :call_taxi, :ride_taxi, :pay_driver)
Hop.declare_methods(:travel, :travel_by_foot, :travel_by_taxi)

puts 'DEBUG', Hop.actions.inspect

start = {
  :name => 'state1',
  :loc => {'me' => 'home'},
  :cash => {'me' => 20},
  :owe => {'me' => 0},
  :dist => {'home' => {'park' => 8}, 'park' => {'home' => 8}}
}

4.times {|verbosity|
  puts verbosity
  Hop.plan(start, [[:travel,'me','home','park']], verbosity)
  puts '~' * 60
}