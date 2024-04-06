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
        substitutions = {}
        if precond_pos.each {|pre,*terms|
          unless predicates[pre]
            if not s = state[pre] or (not terms.all? {|i| i.start_with?('?')} and (s = s.select {|i| not i.zip(terms) {|a,b| break true unless a == b or b.start_with?('?')}}).empty?) then break
            elsif s.size == 1 and not (terms & free).empty? then terms.zip(s[0]) {|a,b| substitutions[a] = b if a != b}
            end
          end
        }
          if substitutions.empty?
            subtasks.each {|t,| counter[t] += 1}
          else
            free.reject! {|i| substitutions.include?(i)}
            precond_pos.each {|pre| pre.map! {|i| substitutions[i] || i}}
            precond_not.each {|pre| pre.map! {|i| substitutions[i] || i}}
            subtasks.each {|t| counter[t.map! {|i| substitutions[i] || i}[0]] += 1}
          end
        end
      }
      if decompositions.empty?
        impossible << name
        raise "Domain defines no decomposition for #{name}" if tasks.assoc(name)
      else decompositions.unshift(name, param)
      end
    }
    operators.reject! {|op| impossible << op[0] unless counter.include?(op[0]) and op[2].all? {|pre,| predicates[pre] || state.include?(pre)}}
    # Move current or rigid predicates from leaves to root/entry tasks
    clear_ops = []
    clear_met = []
    first_pass = repeat = true
    while repeat
      repeat = false
      methods.map! {|name,param,*decompositions|
        decompositions.select! {|_,_,precond_pos,precond_not,subtasks|
          first_task = true
          effects = Hash.new(0)
          old_precond_pos_size = precond_pos.size
          old_precond_not_size = precond_not.size
          subtasks.each {|s|
            if impossible.include?(s[0])
              repeat = true
              subtasks.each {|i,| operators.delete_at(i) if (counter[i] -= 1) == 0 and i = operators.index {|op,| op == i}}
              break
            elsif op = operators.assoc(s[0])
              op[2].each {|pre| precond_pos << pre.map {|t| (j = op[1].index(t)) ? s[j + 1] : t} if effects[pre[0]].even?}
              op[3].each {|pre| precond_not << pre.map {|t| (j = op[1].index(t)) ? s[j + 1] : t} if effects[pre[0]] < 2}
              op[4].each {|pre,| effects[pre] |= 1}
              op[5].each {|pre,| effects[pre] |= 2}
              if first_task and counter[s[0]] == 1
                op[2].clear
                op[3].clear
              elsif first_pass and not tasks.assoc(s[0]) then clear_ops << op
              end
            else
              all_pos = all_neg = nil
              metdecompositions = (met = methods.assoc(s[0])).drop(2).each {|m|
                pos = []
                neg = []
                m[2].each {|pre|
                  if effects[pre[0]].even?
                    pre = pre.map {|t| (j = met[1].index(t)) ? s[j + 1] : t}
                    pos << pre if (pre & m[1]).empty?
                  end
                }
                m[3].each {|pre|
                  if effects[pre[0]] < 2
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
              clear_met << [metdecompositions, all_pos, all_neg] unless tasks.assoc(s[0])
              precond_pos.concat(all_pos)
              precond_not.concat(all_neg)
            end
            precond_pos.uniq!
            precond_not.uniq!
            # Add equality duplicates
            equalities = Hash.new {|h,k| h[k] = []}
            precond_pos.each {|pre|
              if pre[0] == '='
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
                if pre[0] != '='
                  modified = false
                  npre = pre.drop(1).map! {|i|
                    if equalities.include?(i)
                      modified = true
                      equalities[i]
                    else [i]
                    end
                  }
                  new_precond_pos.concat([pre[0]].product(*npre)) if modified
                end
              }.concat(new_precond_pos).uniq!
            end
            repeat = true if old_precond_pos_size != precond_pos.size or old_precond_not_size != precond_not.size
            first_task = false
          }
        }
        if decompositions.empty?
          impossible << name
          raise "Domain defines no decomposition for #{name}" if tasks.assoc(name)
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
        # Remove unnecessary free variables
        substitutions = {}
        precond_pos.each {|pre,*terms|
          if not predicates[pre] and not (terms & free).empty? and s = state[pre]
            sub = nil
            terms.zip(sub) {|a,b| substitutions[a] = b if a != b} if s.each {|i| sub ? break : sub = i unless i.zip(terms) {|a,b| break true unless a == b or b.start_with?('?')}}
          end
        }
        unless substitutions.empty?
          free.reject! {|i| substitutions.include?(i)}
          precond_pos.each {|pre| pre.map! {|i| substitutions[i] || i}}
          precond_not.each {|pre| pre.map! {|i| substitutions[i] || i}}
          subtasks.each {|t| t.map! {|i| substitutions[i] || i}}
        end
        precond_pos.delete_if {|pre|
          if not predicates[pre[0]] and pre.none? {|i| i.start_with?('?')}
            break unless state[pre[0]]&.include?(pre.drop(1))
            true
          end
        } &&
        precond_not.delete_if {|pre|
          if not predicates[pre[0]] and pre.none? {|i| i.start_with?('?')}
            break if state[pre[0]]&.include?(pre.drop(1))
            true
          end
        }
      }
      decompositions.unshift(name, param)
    }
    # Remove dead leaves
    clear_met.each {|decompositions,pos,neg|
      decompositions.each {|dec|
        dec[2] -= pos
        dec[3] -= neg
      }
    }
    clear_ops.uniq!(&:object_id)
    clear_ops.each {|op|
      op[2].select! {|pre,| predicates[pre]}
      op[3].select! {|pre,| predicates[pre]}
    }
    # Update mutability
    predicates.transform_values! {}
    operators.each {|_,_,precond_pos,precond_not,effect_add,effect_del|
      precond_pos.each {|pre,| predicates[pre.freeze] ||= false}
      precond_not.each {|pre,| predicates[pre.freeze] ||= false}
      effect_add.each {|pre,| predicates[pre.freeze] = true}
      effect_del.each {|pre,| predicates[pre.freeze] = true}
    }
    methods.each {|decompositions|
      decompositions.drop(2).each {|m|
        m[2].each {|pre,| predicates[pre.freeze] ||= false}
        m[3].each {|pre,| predicates[pre.freeze] ||= false}
      }
    }
    goal_pos.each {|pre,| predicates[pre.freeze] ||= false}
    goal_not.each {|pre,| predicates[pre.freeze] ||= false}
    tasks.unshift(ordered) unless tasks.empty?
  end

  #-----------------------------------------------
  # Mark effects
  #-----------------------------------------------

  def mark_effects(operators, methods, decompositions, effects, visited = {})
    decompositions.each {|dec|
      dec[4].each {|s,|
        unless visited.include?(s)
          visited[s] = nil
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