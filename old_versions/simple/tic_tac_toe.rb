require File.expand_path('../Hypertension_simple', __FILE__)
# check http://www.se16.info/hgb/tictactoe.htm

#-----------------------------------------------
# State Copy
#-----------------------------------------------

def Hypertension_simple.state_copy(state)
  state.dup
end

#-----------------------------------------------
# Definitions
#-----------------------------------------------

def make_move_n(state, player, n)
  if state[n].zero?
    state[n] = player
    state
  end
end

def game_over?(state, i, j, k)
  state[i] & state[j] & state[k] != 0
end

#-----------------------------------------------
# Operators
#-----------------------------------------------

def make_move_0(state, player)
  make_move_n(state, player, 0)
end

def make_move_1(state, player)
  make_move_n(state, player, 1)
end

def make_move_2(state, player)
  make_move_n(state, player, 2)
end

def make_move_3(state, player)
  make_move_n(state, player, 3)
end

def make_move_4(state, player)
  make_move_n(state, player, 4)
end

def make_move_5(state, player)
  make_move_n(state, player, 5)
end

def make_move_6(state, player)
  make_move_n(state, player, 6)
end

def make_move_7(state, player)
  make_move_n(state, player, 7)
end

def make_move_8(state, player)
  make_move_n(state, player, 8)
end

def game_over(state, expected)
  endgame = false
  if game_over?(state, 0, 1, 2)
    endgame = true
  elsif game_over?(state, 3, 4, 5)
    endgame = true
  elsif game_over?(state, 6, 7, 8)
    endgame = true
  elsif game_over?(state, 0, 3, 6)
    endgame = true
  elsif game_over?(state, 1, 4, 7)
    endgame = true
  elsif game_over?(state, 2, 5, 8)
    endgame = true
  elsif game_over?(state, 0, 4, 8)
    endgame = true
  elsif game_over?(state, 2, 4, 6)
    endgame = true
  elsif state.none? {|i| i.zero?}
    endgame = true
  end
  state if expected == endgame
end

#-----------------------------------------------
# Methods
#-----------------------------------------------

def play_tic_tac_toe(state)
  [[:ply, 1]]
end

def ply_end(state, player)
  [[:make_move, player], [:game_over, true]]
end

def ply_continue(state, player)
  [[:make_move, player], [:game_over, false], [:ply, player ^ 3]]
end

#-----------------------------------------------
# Actions
#-----------------------------------------------

PROBABILISTIC_ACTIONS = {
  # Operators
  :game_over => 1,
  # Probabilistic operators
  :make_move => {
    :make_move_0 => 1.0 / 9,
    :make_move_1 => 1.0 / 9,
    :make_move_2 => 1.0 / 9,
    :make_move_3 => 1.0 / 9,
    :make_move_4 => 1.0 / 9,
    :make_move_5 => 1.0 / 9,
    :make_move_6 => 1.0 / 9,
    :make_move_7 => 1.0 / 9,
    :make_move_8 => 1.0 / 9
  },
  # Methods
  :play_tic_tac_toe => [
    :play_tic_tac_toe
  ],
  :ply => [
    :ply_end,
    :ply_continue
  ]
}

#-----------------------------------------------
# Start
#-----------------------------------------------

START = [0,0,0,
         0,0,0,
         0,0,0]

#-----------------------------------------------
# Tasks
#-----------------------------------------------

TASKS = [
  [[:play_tic_tac_toe]]
]

#-----------------------------------------------
# Main
#-----------------------------------------------

begin
  TASKS.each {|task|
    puts '-' * 50
    t = Time.now.to_f
    puts "Goal: #{task.map {|i| "#{i.first}(#{i.drop(1).join(', ')})"}.join(' & ')}"
    plan = Hypertension_simple.probabilistic_planning(START, PROBABILISTIC_ACTIONS, task)
    if plan
      puts plan.size
      puts "Time: #{Time.now.to_f - t}s"
      Hypertension_simple.print_probabilistic_plan(plan)
    else
      puts 'Planning failed'
    end
  }
rescue Interrupt
  puts 'Interrupted'
rescue
  puts $!, $@
  STDIN.gets
end