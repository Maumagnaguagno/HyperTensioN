module Dummy
  extend self

  VISIT = 'visitp' # Use 'visit' to enable caching

  #-----------------------------------------------
  # Apply
  #-----------------------------------------------

  def apply(operators, methods, predicates, state, tasks, goal_pos, goal_not, repetitions = 1)
    return if goal_pos.empty? and goal_not.empty?
    # Tasks are unordered
    tasks[0] = false
    # Invisible operators are rejected from search
    visible_operators = operators.reject {|op,| op.start_with?('invisible_')}
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
    visible_operators.each {|name,param|
      visit = "#{VISIT}_#{name}"
      1.upto(repetitions) {|i|
        predicates[visited = "visited_#{name}_#{i}".freeze] = true
        operators.push(
          ["invisible_#{visit}_#{i}", param,
            # Positive preconditions
            [],
            # Negative preconditions
            [[visited, *param]],
            # Add effect
            [[visited, *param]],
            # Del effect
            []
          ],
          ["invisible_un#{visit}_#{i}", param,
            # Positive preconditions
            [],
            # Negative preconditions
            [],
            # Add effect
            [],
            # Del effect
            [[visited, *param]]
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
    operators.each {|name,param,precond_pos,precond_not|
      act = [name, *param]
      if repetitions.zero? # Actions can be reused
        perform << ["try_#{name}_to_#{task}", param,
          # Positive preconditions
          precond_pos,
          # Negative preconditions
          precond_not,
          # Subtasks
          [
            act,
            [task]
          ]
        ]
      else # Actions are visited and unvisited to avoid infinite repetition
        visit = "#{VISIT}_#{name}"
        1.upto(repetitions) {|i|
          perform << ["try_#{name}_to_#{task}#{i}", param,
            # Positive preconditions
            precond_pos,
            # Negative preconditions
            i == 1 ? precond_not : [["visited_#{name}_#{i.pred}", *param], *precond_not],
            # Subtasks
            [
              ["invisible_#{visit}_#{i}", *param],
              act,
              [task],
              ["invisible_un#{visit}_#{i}", *param]
            ]
          ]
        }
      end
    }
  end
end