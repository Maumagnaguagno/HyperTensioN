module Typredicate
  extend self

  #-----------------------------------------------
  # Apply
  #-----------------------------------------------

  def apply(operators, methods, predicates, state, tasks, goal_pos, goal_not, debug = false)
    new_predicates = {}
    operator_types = {}
    operators.each {|name,_,precond_pos,precond_not,_,_|
      next if name.start_with?('invisible_')
      operator_types[name] = types = {}
      precond_pos.each {|terms| types[terms.last] ||= terms.first if terms.size == 2 and not predicates[terms.first]}
      precond_pos.each {|terms| (new_predicates[terms.first] ||= []) << types.values_at(*terms.drop(1))}
    }
    (supertypes = (PDDL_Parser.types || HDDL_Parser.types).map(&:last)).uniq!
    transformations = {}
    new_predicates.each {|pre,types|
      types.uniq!
      types.reject! {|t| t.include?(nil)}
      next if types.size == 1
      if (supertypes & types.flatten.uniq).empty?
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
    methods.each {|decompositions|
      decompositions.drop(2).each {|_,_,precond_pos,precond_not,_|
        types = {}
        precond_pos.each {|terms| types[terms.last] ||= terms.first if terms.size == 2 and not predicates[terms.first]}
        next if types.empty?
        precond_pos.each {|terms| pre = terms.shift; terms.unshift(transformations[types.values_at(*terms).unshift(pre)] || pre)}
        precond_not.each {|terms| pre = terms.shift; terms.unshift(transformations[types.values_at(*terms).unshift(pre)] || pre)}
      }
    }
    new_state = Hash.new {|h,k| h[k] = []}
    transformations.each {|(tpre,*tterms),v| s = state[tpre] and s.each {|terms| new_state[v] << terms if tterms.zip(terms).all? {|t| state[t.shift].include?(t)}}}
    state.merge!(new_state)
    transformations.each_key {|k| predicates.delete(k.first)}
  end

  def ground_transform(state, group, transformations)
    group.each {|terms|
      pre = terms.shift
      transformations.each {|(tpre,*tterms),v| break pre = v if tpre == pre and tterms.zip(terms).all? {|t| state[t.shift].include?(t)}}
      terms.unshift(pre)
    }
  end
end