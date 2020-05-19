module Pullup
  extend self

  #-----------------------------------------------
  # Apply
  #-----------------------------------------------

  def apply(operators, methods, predicates, state, tasks, goal_pos, goal_not, debug = false)
    # Remove impossible operators and methods and unnecessary free variables
    impossible = []
    counter = Hash.new(0)
    tasks.drop(1).each {|t| counter[t.first] += 1}
    methods.map! {|name,param,*decompositions|
      decompositions.select! {|label,free,precond_pos,precond_not,subtasks|
        substitutions = []
        if precond_pos.each {|pre|
          unless predicates[pre.first]
            if (s = state.select {|i| i.zip(pre).all? {|a,b| a == b or b.start_with?('?')}}).empty? then break
            elsif s.size == 1 and not (pre & free).empty? then substitutions.concat(pre.zip(s.first).select! {|a,b| a != b})
            end
          end
        }
          if substitutions.empty?
            subtasks.each {|t| counter[t.first] += 1}
          else
            free.reject! {|i| substitutions.assoc(i)}
            precond_pos.each {|pre| pre.map! {|i| (s = substitutions.assoc(i)) ? s.last : i}}
            precond_not.each {|pre| pre.map! {|i| (s = substitutions.assoc(i)) ? s.last : i}}
            subtasks.each {|t|
              t.map! {|i| (s = substitutions.assoc(i)) ? s.last : i}
              counter[t.first] += 1
            }
          end
        end
      }
      if decompositions.empty?
        impossible << name
        repeat = true
        nil
      else decompositions.unshift(name, param)
      end
    }.compact!
    operators.reject! {|op| impossible << op.first if not counter.include?(op.first) or op[2].any? {|pre| not predicates[pre.first] and state.none? {|i| i.first == pre.first}}}
    # Move current or rigid predicates from leaves to root/entry tasks
    clear_ops = []
    clear_met = []
    first_pass = repeat = true
    while repeat
      repeat = false
      methods.map! {|name,param,*decompositions|
        decompositions.select! {|label,free,precond_pos,precond_not,subtasks|
          first_task = operator_sequence = true
          effects = []
          old_precond_pos_size = precond_pos.size
          old_precond_not_size = precond_not.size
          subtasks.each {|s|
            if impossible.include?(s.first)
              repeat = true
              subtasks.each {|i| operators.delete_if {|op| op.first == i.first} if (counter[i.first] -= 1) == 0}
              break
            elsif op = operators.assoc(s.first)
              if operator_sequence
                op[2].each {|pre| precond_pos << pre.map {|t| (j = op[1].index(t)) ? s[j + 1] : t} unless effects.include?(pre.first)}
                op[3].each {|pre| precond_not << pre.map {|t| (j = op[1].index(t)) ? s[j + 1] : t} unless effects.include?(pre.first)}
                op[4].each {|pre| effects << pre.first}
                op[5].each {|pre| effects << pre.first}
              else
                op[2].each {|pre| precond_pos << pre.map {|t| (j = op[1].index(t)) ? s[j + 1] : t} unless predicates[pre.first]}
                op[3].each {|pre| precond_not << pre.map {|t| (j = op[1].index(t)) ? s[j + 1] : t} unless predicates[pre.first]}
              end
              if first_task and counter[s.first] == 1
                op[2].clear
                op[3].clear
              elsif first_pass and not tasks.assoc(s.first) then clear_ops << op
              end
            else
              all_pos = all_neg = nil
              (metdecompositions = (met = methods.assoc(s.first)).drop(2)).each {|m|
                pos = []
                neg = []
                if operator_sequence
                  m[2].each {|pre| pos << pre.map {|t| (j = met[1].index(t)) ? s[j + 1] : t} if not effects.include?(pre.first) and (pre & m[1]).empty?}
                  m[3].each {|pre| neg << pre.map {|t| (j = met[1].index(t)) ? s[j + 1] : t} if not effects.include?(pre.first) and (pre & m[1]).empty?}
                else
                  m[2].each {|pre| pos << pre.map {|t| (j = met[1].index(t)) ? s[j + 1] : t} if not predicates[pre.first] and (pre & m[1]).empty?}
                  m[3].each {|pre| neg << pre.map {|t| (j = met[1].index(t)) ? s[j + 1] : t} if not predicates[pre.first] and (pre & m[1]).empty?}
                end
                if all_pos
                  all_pos &= pos
                  all_neg &= neg
                else
                  all_pos = pos
                  all_neg = neg
                end
              }
              clear_met << [metdecompositions, all_pos, all_neg] unless tasks.assoc(s.first)
              precond_pos.concat(all_pos)
              precond_not.concat(all_neg)
              operator_sequence = false
            end
            precond_pos.uniq!
            precond_not.uniq!
            repeat = true if old_precond_pos_size != precond_pos.size or old_precond_not_size != precond_not.size
            first_task = false
          }
        }
        if decompositions.empty?
          impossible << name
          repeat = true
          nil
        else decompositions.unshift(name, param)
        end
      }.compact!
      first_pass = false
    end
    # Remove dead branches
    methods.map! {|name,param,*decompositions|
      decompositions.select! {|label,free,precond_pos,precond_not,subtasks|
        possible_decomposition = true
        # Remove unnecessary free variables
        substitutions = []
        precond_pos.each {|pre|
          if not predicates[pre.first] and not (pre & free).empty? and (s = state.select {|i| i.zip(pre).all? {|a,b| a == b or b.start_with?('?')}}).size == 1
            substitutions.concat(pre.zip(s.first).select! {|a,b| a != b})
          end
        }
        unless substitutions.empty?
          free.reject! {|i| substitutions.assoc(i)}
          precond_pos.each {|pre| pre.map! {|i| (s = substitutions.assoc(i)) ? s.last : i}}
          precond_not.each {|pre| pre.map! {|i| (s = substitutions.assoc(i)) ? s.last : i}}
          subtasks.each {|t| t.map! {|i| (s = substitutions.assoc(i)) ? s.last : i}}
        end
        precond_pos.reject! {|pre|
          if not predicates[pre.first] and pre.none? {|i| i.start_with?('?')}
            unless state.include?(pre)
              possible_decomposition = false
              break
            end
            true
          end
        }
        if possible_decomposition
          precond_not.reject! {|pre|
            if not predicates[pre.first] and pre.none? {|i| i.start_with?('?')}
              if state.include?(pre)
                possible_decomposition = false
                break
              end
              true
            end
          }
        end
        possible_decomposition
      }
      decompositions.unshift(name, param)
    }
    # Remove dead leaves
    clear_met.each {|metdecompositions,pos,neg|
      metdecompositions.each {|m|
        m[2] -= pos
        m[3] -= neg
      }
    }
    clear_ops.uniq!
    clear_ops.each {|op|
      op[2].select! {|pre| predicates[pre.first]}
      op[3].select! {|pre| predicates[pre.first]}
    }
    # Move missing base condition to recursion
    methods.each {|name,param,*decompositions|
      precond_pos_all = []
      precond_not_recursion = nil
      decompositions.each {|label,free,precond_pos,precond_not,subtasks|
        if not subtasks.empty? and subtasks.first.first.start_with?('invisible_')
          precond_not_recursion = precond_not
        else precond_pos_all.concat(precond_pos)
        end
      }
      if precond_not_recursion
        precond_pos_all.uniq!
        precond_pos_all.select! {|pre| predicates[pre.first] and pre.all? {|i| not i.start_with?('?') or param.include?(i)}}
        precond_not_recursion.concat(precond_pos_all).uniq!
      end
    }
  end
end