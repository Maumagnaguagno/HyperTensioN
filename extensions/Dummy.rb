module Dummy
  extend self

  #-----------------------------------------------
  # Apply
  #-----------------------------------------------

  def apply(operators, methods, predicates, state, tasks, goal_pos, goal_not, repetitions = 1)
    puts 'Dummy'.center(50,'-')
    t = Time.now.to_f
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
      1.upto(repetitions) {|i|
        predicates[visited = "visited_#{op.first}_#{i}".freeze] = true
        operators.push(
          ["invisible_visit_#{op.first}_#{i}", op[1],
            # Positive preconditions
            [],
            # Negative preconditions
            [[visited, *op[1]]],
            # Add effect
            [[visited, *op[1]]],
            # Del effect
            []
          ],
          ["invisible_unvisit_#{op.first}_#{i}", op[1],
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
    puts "Repetitions: #{repetitions}\nConversion time: #{Time.now.to_f - t}s"
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
      act = op.first(2).flatten
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
        1.upto(repetitions) {|i|
          perform << ["try_#{op.first}_to_#{task}#{i}", op[1],
            # Positive preconditions
            op[2],
            # Negative preconditions
            op[3],
            # Subtasks
            [
              ["invisible_visit_#{op.first}_#{i}", *op[1]],
              act,
              [task],
              ["invisible_unvisit_#{op.first}_#{i}", *op[1]]
            ]
          ]
        }
      end
    }
  end
end