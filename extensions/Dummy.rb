module Dummy
  extend self

  VISIT = 'visitp' # Use 'visit' to enable caching

  #-----------------------------------------------
  # Apply
  #-----------------------------------------------

  def apply(operators, methods, predicates, state, tasks, goal_pos, goal_not, debug = false, repetitions = 1)
    puts 'Dummy'.center(50,'-'), "Repetitions: #{repetitions}" if debug
    # Tasks are unordered
    tasks << false if tasks.empty?
    # Invisible operators are rejected from search
    visible_operators = operators.reject {|op| op.first.start_with?('invisible_')}
    # Each goal generates a task and a set of methods
    goal_pos.each {|pre|
      tasks << [name = "perform_goal_#{pre.join('_')}"]
      generate_methods(visible_operators, methods, name, [pre], [], repetitions)
    }
    goal_not.each {|pre|
      tasks << [name = "perform_goal_not_#{pre.join('_')}"]
      generate_methods(visible_operators, methods, name, [], [pre], repetitions)
    }
    # Visible operators are visited to avoid infinite repetition
    visible_operators.each {|op|
      name = "#{VISIT}_#{op.first}"
      1.upto(repetitions) {|i|
        predicates[visited = "visited_#{op.first}_#{i}".freeze] = true
        operators.push(
          ["invisible_#{name}_#{i}", op[1],
            # Positive preconditions
            [],
            # Negative preconditions
            [[visited, *op[1]]],
            # Add effect
            [[visited, *op[1]]],
            # Del effect
            []
          ],
          ["invisible_un#{name}_#{i}", op[1],
            # Positive preconditions
            [],
            # Negative preconditions
            [],
            # Add effect
            [],
            # Del effect
            [[visited, *op[1]]]
          ]
        )
      }
    }
  end

  #-----------------------------------------------
  # Generate methods
  #-----------------------------------------------

  def generate_methods(operators, methods, task, precond_pos, precond_not, repetitions)
    # Base of recursion is goal present in the preconditions
    methods << perform = [task, [],
      ["finish_#{task}", [],
        # Positive preconditions
        precond_pos,
        # Negative preconditions
        precond_not,
        # Subtasks
        []
      ]
    ]
    # Tail is composed of operators
    operators.each {|op|
      act = [op[0], *op[1]]
      if repetitions.zero? # Actions can be reused
        perform << ["try_#{op.first}_to_#{task}", op[1],
          # Positive preconditions
          op[2],
          # Negative preconditions
          op[3],
          # Subtasks
          [
            act,
            [task]
          ]
        ]
      else # Actions are visited and unvisited to avoid infinite repetition
        name = "#{VISIT}_#{op.first}"
        1.upto(repetitions) {|i|
          perform << ["try_#{op.first}_to_#{task}#{i}", op[1],
            # Positive preconditions
            op[2],
            # Negative preconditions
            i == 1 ? op[3] : [["visited_#{op.first}_#{i.pred}", *op[1]]].concat(op[3]),
            # Subtasks
            [
              ["invisible_#{name}_#{i}", *op[1]],
              act,
              [task],
              ["invisible_un#{name}_#{i}", *op[1]]
            ]
          ]
        }
      end
    }
  end
end