module Typredicate
  extend self

  #-----------------------------------------------
  # Apply
  #-----------------------------------------------

  def apply(operators, methods, predicates, state, tasks, goal_pos, goal_not, debug = false)
    (supertypes = (PDDL_Parser.types || HDDL_Parser.types || return).map(&:last)).uniq!
    new_predicates = {}
    operator_types = {}
    operators.each {|name,_,precond_pos,precond_not,effect_add,effect_del|
      operator_types[name] = types = {}
      precond_pos.each {|terms| types[terms.last] ||= terms.first if terms.size == 2 and not predicates[terms.first]}
      find_types(precond_pos, types, new_predicates)
      find_types(precond_not, types, new_predicates)
      find_types(effect_add, types, new_predicates)
      find_types(effect_del, types, new_predicates)
    }
    transformations = {}
    new_predicates.each {|pre,types|
      types.uniq!
      next if types.size == 1 or not (supertypes & types.flatten(1).uniq).empty?
      types.each {|t| predicates[transformations[t] = t.unshift(pre).join('_')] = predicates[pre] if t.all? {|p| state.include?(p)}}
    }
    return if transformations.empty?
    operators.each {|name,_,precond_pos,precond_not,effect_add,effect_del|
      next if (types = operator_types[name]).empty?
      precond_pos.each {|terms| pre = terms.shift; terms.unshift(transformations[types.values_at(*terms).unshift(pre)] || pre)}
      precond_not.each {|terms| pre = terms.shift; terms.unshift(transformations[types.values_at(*terms).unshift(pre)] || pre)}
      effect_add.each {|terms| pre = terms.shift; terms.unshift(transformations[types.values_at(*terms).unshift(pre)] || pre)}
      effect_del.each {|terms| pre = terms.shift; terms.unshift(transformations[types.values_at(*terms).unshift(pre)] || pre)}
    }
    methods.each {|met|
      met.drop(2).each {|_,_,precond_pos,precond_not|
        types = {}
        precond_pos.each {|terms| types[terms.last] ||= terms.first if terms.size == 2 and not predicates[terms.first]}
        next if types.empty?
        precond_pos.each {|terms| pre = terms.shift; terms.unshift(transformations[types.values_at(*terms).unshift(pre)] || pre)}
        precond_not.each {|terms| pre = terms.shift; terms.unshift(transformations[types.values_at(*terms).unshift(pre)] || pre)}
      }
    }
    ground_transform(state, goal_pos, transformations)
    ground_transform(state, goal_not, transformations)
    transformations.each {|(tpre,*tterms),v|
      n = state[tpre]&.reject {|terms| tterms.zip(terms) {|t| break true unless state[t.shift].include?(t)}}
      state[v] = n if n and not n.empty?
      predicates.delete(tpre)
    }
  end

  #-----------------------------------------------
  # Find types
  #-----------------------------------------------

  def find_types(group, types, new_predicates)
    group.each {|pre,*terms|
      values = types.values_at(*terms)
      (new_predicates[pre] ||= []) << values unless values.include?(nil)
    }
  end

  #-----------------------------------------------
  # Ground transform
  #-----------------------------------------------

  def ground_transform(state, group, transformations)
    group.each {|terms|
      pre = terms.shift
      transformations.each {|(tpre,*tterms),v| break pre = v if tpre == pre and not tterms.zip(terms) {|t| break true unless state[t.shift].include?(t)}}
      terms.unshift(pre)
    }
  end
end