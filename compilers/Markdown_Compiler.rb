module Markdown_Compiler
  extend self

  #-----------------------------------------------
  # Compile domain
  #-----------------------------------------------

  def compile_domain(domain_name, problem_name, operators, methods, predicates, state, tasks, goal_pos, goal_not)
    output = "# #{domain_name.capitalize}\n## Predicates\n"
    predicates.each {|pre,v| output << "- **#{pre}**: #{v ? 'fluent' : 'rigid'}\n"}
    state.each_key {|pre| output << "- **#{pre}**: irrelevant\n" unless predicates.include?(pre)}
    unless operators.empty?
      output << "\n## Operators"
      operators.each {|name,param,precond_pos,precond_not,effect_add,effect_del|
        output << "\n#{name.capitalize} | #{param.join(' ')}\n--- | ---\n***Preconditions*** | ***Effects***\n"
        precond_pos.each {|pre| output << "(#{pre.join(' ')}) |#{" **not** (#{pre.join(' ')})" if effect_del.include?(pre)}\n"}
        precond_not.each {|pre| output << "**not** (#{pre.join(' ')}) |#{" (#{pre.join(' ')})" if effect_add.include?(pre)}\n"}
        effect_add.each {|pre| output << "|| (#{pre.join(' ')})\n" unless precond_not.include?(pre)}
        effect_del.each {|pre| output << "|| **not** (#{pre.join(' ')})\n" unless precond_pos.include?(pre)}
      }
    end
    unless methods.empty?
      output << "\n## Methods"
      methods.each_with_index {|(name,param,*decompositions),i|
        output << "\n#{name.capitalize} | #{param.join(' ')} ||\n--- | --- | ---\n***Label*** | ***Preconditions*** | ***Subtasks***"
        decompositions.each {|label,_,precond_pos,precond_not,subtasks|
          output << "\n|#{label}"
          index = 0
          precond_pos.each {|pre|
            output << "\n|| (#{pre.join(' ')}) | #{subtasks[index]&.join(' ')}"
            index += 1
          }
          precond_not.each {|pre|
            output << "\n|| **not** (#{pre.join(' ')}) | #{subtasks[index]&.join(' ')}"
            index += 1
          }
          subtasks.drop(index).each {|task| output << "\n||| #{task.join(' ')}"}
        }
        output << "\n" if i != methods.size.pred
      }
    end
    output
  end

  #-----------------------------------------------
  # Compile problem
  #-----------------------------------------------

  def compile_problem(domain_name, problem_name, operators, methods, predicates, state, tasks, goal_pos, goal_not, domain_filename)
    output = "# #{problem_name.capitalize} of #{domain_name.capitalize}\n## Initial state"
    state.each {|pre,k| k.each {|terms| output << "\n- (#{[pre, *terms].join(' ')})"}}
    unless tasks.empty?
      ordered = tasks.shift
      output << (ordered ? "\n\n## Tasks\n**ordered**" : "\n\n## Tasks\n**unordered**")
      tasks.each {|task| output << "\n- (#{task.join(' ')})"}.unshift(ordered)
    end
    unless goal_pos.empty? and goal_not.empty?
      output << "\n\n## Goal state"
      goal_pos.each {|pre| output << "\n- (#{pre.join(' ')})"}
      goal_not.each {|pre| output << "\n- **not** (#{pre.join(' ')})"}
    end
    output
  end
end