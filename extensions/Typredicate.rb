module Typredicate
  extend self

  #-----------------------------------------------
  # Apply
  #-----------------------------------------------

  def apply(operators, methods, predicates, state, tasks, goal_pos, goal_not, debug = false)
    (supertypes = (PDDL_Parser.types || HDDL_Parser.types || return).map(&:last)).uniq!
    new_predicates = {}
    operator_types = {}
    operators.each {|name,_,precond_pos,precond_not|
      next if name.start_with?('invisible_')
      operator_types[name] = types = {}
      precond_pos.each {|terms| types[terms.last] ||= terms.first if terms.size == 2 and not predicates[terms.first]}
      precond_pos.each {|terms|
        values = types.values_at(*terms.drop(1))
        (new_predicates[terms.first] ||= []) << values unless values.include?(nil)
      }
    }
    transformations = {}
    new_predicates.each {|pre,types|
      types.uniq!
      next if types.size == 1
      if (supertypes & types.flatten(1).uniq).empty?
        types.each {|t| predicates[transformations[t] = t.unshift(pre).join('_')] = predicates[pre] if t.all? {|p| state.include?(p)}}
      end
    }
    return if transformations.empty?
    operators.each {|name,_,precond_pos,precond_not,effect_add,effect_del|
      next if name.start_with?('invisible_') or (types = operator_types[name]).empty?
      precond_pos.each {|terms| pre = terms.shift; terms.unshift(transformations[types.values_at(*terms).unshift(pre)] || pre)}
      precond_not.each {|terms| pre = terms.shift; terms.unshift(transformations[types.values_at(*terms).unshift(pre)] || pre)}
      effect_add.each {|terms| pre = terms.shift; terms.unshift(transformations[types.values_at(*terms).unshift(pre)] || pre)}
      effect_del.each {|terms| pre = terms.shift; terms.unshift(transformations[types.values_at(*terms).unshift(pre)] || pre)}
    }
    if operators.last.first == 'invisible_goal'
      _, _, precond_pos, precond_not, effect_add, effect_del = operators.last
      ground_transform(state, precond_pos, transformations)
      ground_transform(state, precond_not, transformations)
      ground_transform(state, effect_add, transformations)
      ground_transform(state, effect_del, transformations)
    end
    methods.each {|met|
      met.drop(2).each {|_,_,precond_pos,precond_not|
        types = {}
        precond_pos.each {|terms| types[terms.last] ||= terms.first if terms.size == 2 and not predicates[terms.first]}
        next if types.empty?
        precond_pos.each {|terms| pre = terms.shift; terms.unshift(transformations[types.values_at(*terms).unshift(pre)] || pre)}
        precond_not.each {|terms| pre = terms.shift; terms.unshift(transformations[types.values_at(*terms).unshift(pre)] || pre)}
      }
    }
    new_state = Hash.new {|h,k| h[k] = []}
    transformations.each {|(tpre,*tterms),v|
      state[tpre]&.each {|terms| new_state[v] << terms unless tterms.zip(terms) {|t| break true unless state[t.shift].include?(t)}}
      predicates.delete(tpre)
    }
    state.merge!(new_state)
  end

  def ground_transform(state, group, transformations)
    group.each {|terms|
      pre = terms.shift
      transformations.each {|(tpre,*tterms),v| break pre = v if tpre == pre and not tterms.zip(terms) {|t| break true unless state[t.shift].include?(t)}}
      terms.unshift(pre)
    }
  end
end