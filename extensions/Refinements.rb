module Refinements
  extend self

  INVISIBLE = true

  def apply(operators, methods, predicates, state, tasks, goal_pos, goal_not, debug = true)
    puts 'Refinements'.center(50,'-') if debug
    # Cluster sequential operators
    cluster = []
    methods.each {|met|
      met.drop(2).each {|dec|
        new_subtasks = []
        dec[4].each {|subtask|
          if op = operators.assoc(subtask.first)
            cluster << [op, subtask.drop(1)]
          else
            add_cluster_to_subtasks(operators, cluster, new_subtasks)
            new_subtasks << subtask
          end
        }
        add_cluster_to_subtasks(operators, cluster, new_subtasks)
        dec[4] = new_subtasks
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
        op[2].each {|pre|
          pre = pre.map {|p| p.start_with?('?') ? param[op[1].index(p)] : p}
          precond_pos << pre unless precond_pos.include?(pre) or effect_add.include?(pre)
        }
        op[3].each {|pre|
          pre = pre.map {|p| p.start_with?('?') ? param[op[1].index(p)] : p}
          precond_not << pre unless precond_not.include?(pre) or effect_del.include?(pre)
        }
        # Effects
        op[4].each {|pre|
          effect_add << pre = pre.map {|p| p.start_with?('?') ? param[op[1].index(p)] : p}
          effect_del.delete(pre)
        }
        op[5].each {|pre|
          effect_del << pre = pre.map {|p| p.start_with?('?') ? param[op[1].index(p)] : p}
          effect_add.delete(pre)
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