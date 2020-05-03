module Pullup
  extend self

  #-----------------------------------------------
  # Apply
  #-----------------------------------------------

  def apply(operators, methods, predicates, state, tasks, goal_pos, goal_not, debug = false)
    # Operator usage
    counter = Hash.new(0)
    tasks.drop(1).each {|t| counter[t.first] += 1 if operators.assoc(t.first)}
    methods.each {|name,param,*decompositions|
      decompositions.each {|label,free,precond_pos,precond_not,subtasks|
        subtasks.each {|t| counter[t.first] += 1 if operators.assoc(t.first)}
      }
    }
    # Move common static predicates from leaves to root/entry task(s)
    clear_ops = []
    methods.each {|name,param,*decompositions|
      decompositions.each {|label,free,precond_pos,precond_not,subtasks|
        subtasks.each_with_index {|s,i|
          if op = operators.assoc(s.first)
            op[2].each {|pre| precond_pos << pre.map {|t| (j = op[1].index(t)) ? s[j + 1] : t} if i == 0 or predicates[pre.first] == false}
            precond_pos.uniq!
            op[3].each {|pre| precond_not << pre.map {|t| (j = op[1].index(t)) ? s[j + 1] : t} if i == 0 or predicates[pre.first] == false}
            precond_not.uniq!
            if i == 0 and counter[op.first] == 1
              op[2].clear
              op[3].clear
            elsif not tasks.assoc(s.first) then clear_ops << op
            end
          end
        }
      }
    }
    clear_ops.each {|op|
      op[2].reject! {|pre| predicates[pre.first] == false}
      op[3].reject! {|pre| predicates[pre.first] == false}
    }
  end
end