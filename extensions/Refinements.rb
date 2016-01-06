module Refinements
  extend self

  INVISIBLE = true

  def apply(operators, methods, predicates, state, tasks, goal_pos, goal_not, debug = true)
    puts 'Refinements'.center(50,'-') if debug
    # Cluster sequential operators
    cluster = []
    methods.each {|met|
      met.drop(2).each {|cases|
        new_subtasks = []
        cases[4].each {|subtask|
          if op = operators.assoc(subtask.first)
            cluster << [op, subtask.drop(1)]
          else
            add_cluster_to_subtasks(operators, cluster, new_subtasks)
            new_subtasks << subtask
          end
        }
        add_cluster_to_subtasks(operators, cluster, new_subtasks)
        cases[4] = new_subtasks
      }
    }
    # Clean preconditions based on hierarchy
    # TODO
  end

  def add_cluster_to_subtasks(operators, cluster, new_subtasks)
    if cluster.size > 1
      name = INVISIBLE ? 'invisible_' : ''
      parameters = []
      precond_pos = []
      precond_not = []
      effect_add = []
      effect_del = []
      cluster.each_with_index {|(op,param),i|
        # Header
        name << '_and_' unless i.zero?
        name << op.first.sub(/^invisible_/,'')
        parameters.concat(param)
        # Preconditions
        op[2].each {|pro|
          pro = pro.map {|p| p.start_with?('?') ? param[op[1].index(p)] : p}
          precond_pos << pro unless precond_pos.include?(pro) or effect_add.include?(pro)
        }
        op[3].each {|pro|
          pro = pro.map {|p| p.start_with?('?') ? param[op[1].index(p)] : p}
          precond_not << pro unless precond_not.include?(pro) or effect_del.include?(pro)
        }
        # Effects
        op[4].each {|pro|
          effect_add << pro = pro.map {|p| p.start_with?('?') ? param[op[1].index(p)] : p}
          effect_del.delete(pro)
        }
        op[5].each {|pro|
          effect_del << pro = pro.map {|p| p.start_with?('?') ? param[op[1].index(p)] : p}
          effect_add.delete(pro)
        }
      }
      parameters.uniq!
      # TODO Compare more than just name, variable usage may generate incompatible versions
      operators << [name, parameters, precond_pos, precond_not, effect_add, effect_del] unless operators.assoc(name)
      new_subtasks << [name, *parameters]
      if INVISIBLE
        # Duplicate operators without preconditions or effects only to maintain plan consistent
        cluster.each {|op,param|
          new_subtasks << [name_dup = "#{op.first}_dup", *param]
          operators << [name_dup, op[1], [], [], [], []] unless operators.assoc(name_dup)
        }
      end
      cluster.clear
    elsif cluster.size == 1
      op, param = cluster.shift
      new_subtasks << param.unshift(op.first)
    end
  end
end