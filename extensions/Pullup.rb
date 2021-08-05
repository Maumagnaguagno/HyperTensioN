module Pullup
  extend self

  #-----------------------------------------------
  # Apply
  #-----------------------------------------------

  def apply(operators, methods, predicates, state, tasks, goal_pos, goal_not, debug = false)
    # Remove impossible operators and methods and unnecessary free variables
    impossible = []
    counter = Hash.new(0)
    ordered = tasks.shift
    tasks.each {|t,| counter[t] += 1}
    methods.select! {|decompositions|
      name = decompositions.shift
      param = decompositions.shift
      decompositions.select! {|_,free,precond_pos,precond_not,subtasks|
        substitutions = []
        if precond_pos.each {|pre,*terms|
          unless predicates[pre]
            if not s = state[pre] or (s = s.select {|i| i.zip(terms).all? {|a,b| a == b or b.start_with?('?')}}).empty? then break
            elsif s.size == 1 and not (terms & free).empty? then terms.zip(s.first) {|t| substitutions << t if t.first != t.last}
            end
          end
        }
          if substitutions.empty?
            subtasks.each {|t,| counter[t] += 1}
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
        raise "Domain defines no decomposition for #{name}" if tasks.assoc(name)
        impossible << name
        nil
      else decompositions.unshift(name, param)
      end
    }
    operators.reject! {|op| impossible << op.first if not counter.include?(op.first) or op[2].any? {|pre,| not predicates[pre] || state.include?(pre)}}
    # Move current or rigid predicates from leaves to root/entry tasks
    clear_ops = []
    clear_met = []
    first_pass = repeat = true
    while repeat
      repeat = false
      methods.map! {|name,param,*decompositions|
        decompositions.select! {|_,free,precond_pos,precond_not,subtasks|
          first_task = true
          effects = Hash.new(0)
          old_precond_pos_size = precond_pos.size
          old_precond_not_size = precond_not.size
          subtasks.each {|s|
            if impossible.include?(s.first)
              repeat = true
              subtasks.each {|i,| operators.delete_if {|op,| op == i} if (counter[i] -= 1) == 0}
              break
            elsif op = operators.assoc(s.first)
              op[2].each {|pre| precond_pos << pre.map {|t| (j = op[1].index(t)) ? s[j + 1] : t} if effects[pre.first].even?}
              op[3].each {|pre| precond_not << pre.map {|t| (j = op[1].index(t)) ? s[j + 1] : t} if effects[pre.first] < 2}
              op[4].each {|pre,| effects[pre] |= 1}
              op[5].each {|pre,| effects[pre] |= 2}
              if first_task and counter[s.first] == 1
                op[2].clear
                op[3].clear
              elsif first_pass and not tasks.assoc(s.first) then clear_ops << op
              end
            else
              all_pos = all_neg = nil
              metdecompositions = (met = methods.assoc(s.first)).drop(2).each {|m|
                pos = []
                neg = []
                m[2].each {|pre|
                  if effects[pre.first].even?
                    pre = pre.map {|t| (j = met[1].index(t)) ? s[j + 1] : t}
                    pos << pre if (pre & m[1]).empty?
                  end
                }
                m[3].each {|pre|
                  if effects[pre.first] < 2
                    pre = pre.map {|t| (j = met[1].index(t)) ? s[j + 1] : t}
                    neg << pre if (pre & m[1]).empty?
                  end
                }
                if all_pos
                  all_pos &= pos
                  all_neg &= neg
                else
                  all_pos = pos
                  all_neg = neg
                end
              }
              mark_effects(operators, methods, metdecompositions, effects)
              clear_met << [metdecompositions, all_pos, all_neg] unless tasks.assoc(s.first)
              precond_pos.concat(all_pos)
              precond_not.concat(all_neg)
            end
            precond_pos.uniq!
            precond_not.uniq!
            # Add equality duplicates
            equalities = Hash.new {|h,k| h[k] = []}
            precond_pos.each {|pre|
              if pre.first == '='
                if pre[1].start_with?('?')
                  equalities[pre[2]] << pre[1] unless pre[2].start_with?('?')
                elsif pre[2].start_with?('?')
                  equalities[pre[1]] << pre[2]
                end
              end
            }
            unless equalities.empty?
              new_precond_pos = []
              precond_pos.each {|pre|
                if pre.first != '='
                  modified = false
                  npre = pre.drop(1).map! {|i|
                    if equalities.include?(i)
                      modified = true
                      equalities[i]
                    else [i]
                    end
                  }
                  new_precond_pos.concat([pre.first].product(*npre)) if modified
                end
              }
              precond_pos.concat(new_precond_pos).uniq!
            end
            repeat = true if old_precond_pos_size != precond_pos.size or old_precond_not_size != precond_not.size
            first_task = false
          }
        }
        if decompositions.empty?
          raise "Domain defines no decomposition for #{name}" if tasks.assoc(name)
          impossible << name
          repeat = true
          nil
        else decompositions.unshift(name, param)
        end
      }.compact!
      first_pass = false
    end
    # Remove dead branches
    methods.each {|decompositions|
      name = decompositions.shift
      param = decompositions.shift
      decompositions.select! {|_,free,precond_pos,precond_not,subtasks|
        possible_decomposition = true
        # Remove unnecessary free variables
        substitutions = []
        precond_pos.each {|pre,*terms|
          if not predicates[pre] and not (terms & free).empty? and s = state[pre] and (s = s.select {|i| i.zip(terms).all? {|a,b| a == b or b.start_with?('?')}}).size == 1
            terms.zip(s.first) {|t| substitutions << t if t.first != t.last}
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
            unless s = state[pre.first] and s.include?(pre.drop(1))
              possible_decomposition = false
              break
            end
            true
          end
        }
        if possible_decomposition
          precond_not.reject! {|pre|
            if not predicates[pre.first] and pre.none? {|i| i.start_with?('?')}
              if s = state[pre.first] and s.include?(pre.drop(1))
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
    clear_ops.uniq!(&:object_id)
    clear_ops.each {|op|
      op[2].select! {|pre,| predicates[pre]}
      op[3].select! {|pre,| predicates[pre]}
    }
    tasks.unshift(ordered) unless tasks.empty?
  end

  #-----------------------------------------------
  # Mark effects
  #-----------------------------------------------

  def mark_effects(operators, methods, decompositions, effects, visited = [])
    decompositions.each {|decomposition|
      decomposition.last.each {|s,|
        unless visited.include?(s)
          visited << s
          if op = operators.assoc(s)
            op[4].each {|pre,| effects[pre] |= 1}
            op[5].each {|pre,| effects[pre] |= 2}
          elsif met = methods.assoc(s)
            mark_effects(operators, methods, met.drop(2), effects, visited)
          end
        end
      }
    }
  end
end