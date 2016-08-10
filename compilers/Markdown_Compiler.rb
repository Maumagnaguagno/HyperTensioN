module Markdown_Compiler
  extend self

  #-----------------------------------------------
  # Compile domain
  #-----------------------------------------------

  def compile_domain(domain_name, problem_name, operators, methods, predicates, state, tasks, goal_pos, goal_not)
    output = "# #{domain_name.capitalize}\n## Predicates\n"
    predicates.each {|k,v| output << "- #{k}: #{v ? 'mutable' : 'invariant'}\n"}
    output << "\n## Operators"
    operators.each {|op|
      output << "\n#{op.first.capitalize} | #{op[1].join(' ')}\n--- | ---\n***Preconditions*** | ***Effects***\n"
      op[2].each {|pre| output << "(#{pre.join(' ')}) |#{" **not** (#{pre.join(' ')})" if op[5].include?(pre)}\n"}
      op[3].each {|pre| output << "**not** (#{pre.join(' ')}) |#{" (#{pre.join(' ')})" if op[4].include?(pre)}\n"}
      op[4].each {|pre| output << "|| (#{pre.join(' ')})\n" unless op[3].include?(pre)}
      op[5].each {|pre| output << "|| **not** (#{pre.join(' ')})\n" unless op[2].include?(pre)}
    }
    output << "\n## Methods"
    methods.each_with_index {|(name,param,*decompositions),i|
      output << "\n#{name.capitalize} | #{param.join(' ')} ||\n--- | --- | ---\n***Label*** | ***Preconditions*** | ***Subtasks***"
      decompositions.each {|dec|
        output << "\n#{dec.first} ||"
        index = 0
        dec[2].each {|pre|
          output << "\n|| (#{pre.join(' ')}) | #{dec[4][index].join(' ') if dec[4][index]}"
          index += 1
        }
        dec[3].each {|pre|
          output << "\n|| **not** (#{pre.join(' ')}) | #{dec[4][index].join(' ') if dec[4][index]}"
          index += 1
        }
      }
      output << "\n" if i != methods.size.pred
    }
    output
  end

  #-----------------------------------------------
  # Compile problem
  #-----------------------------------------------

  def compile_problem(domain_name, problem_name, operators, methods, predicates, state, tasks, goal_pos, goal_not, domain_filename)
    output = "# #{problem_name.capitalize} of #{domain_name.capitalize}\n## Initial state"
    state.each {|pre| output << "\n- (#{pre.join(' ')})"}
    output << "\n\n## Tasks"
    unless tasks.empty?
      ordered = tasks.shift
      output << (ordered ? "\n**ordered**" : "\n**unordered**")
      tasks.each {|task| output << "\n- (#{task.join(' ')})"}
      tasks.unshift(ordered)
    end
    output << "\n\n## Goal state"
    goal_pos.each {|pre| output << "\n- (#{pre.join(' ')})"}
    goal_not.each {|pre| output << "\n- **not** (#{pre.join(' ')})"}
    output
  end
end