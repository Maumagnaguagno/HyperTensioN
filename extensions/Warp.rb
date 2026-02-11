# Based on parameter splitting from On Succinct Groundings of HTN Planning Problems
# https://ojs.aaai.org/index.php/AAAI/article/view/6529
module Warp
  extend self

  #-----------------------------------------------
  # Apply
  #-----------------------------------------------

  def apply(operators, methods, predicates, state, tasks, goal_pos, goal_not)
    new_methods = []
    methods.each {|name,param,*decompositions|
      old_param = param
      decompositions.each {|label,free,precond_pos,precond_not,subtasks|
        next if subtasks.size < 2 or free.empty?
        top = new_tasks = []
        top_variables = top_precond_p = top_precond_n = nil
        subtasks.each_with_index {|sub,i|
          # Find free variables used within sub
          f = sub & free
          # Get preconditions related to no free variables and to the ones found before
          precond_p = []
          precond_n = []
          precond_pos.reject! {|pre| precond_p << pre if pre.all? {|t| not t.start_with?('?') or param.include?(t)} or pre.intersect?(f)}
          precond_not.reject! {|pre| precond_n << pre if pre.all? {|t| not t.start_with?('?') or param.include?(t)} or pre.intersect?(f)}
          # Find related variables
          precond_p.each {|pre| pre.each {|t| f << t if t.start_with?('?') and not param.include?(t)}}
          precond_n.each {|pre| pre.each {|t| f << t if t.start_with?('?') and not param.include?(t)}}
          f.uniq!
          free.replace(free - f)
          # Find preconditions with related variables
          precond_pos.reject! {|pre| precond_p << pre if pre.intersect?(f)}
          precond_not.reject! {|pre| precond_n << pre if pre.intersect?(f)}
          # It is just a jump to the left, and a step to the right
          if i == 0
            top_variables = f
            top_precond_p = precond_p
            top_precond_n = precond_n
          elsif not f.empty?
            new_tasks << [new_name = "warp_#{name}_#{label}_#{i}", *param]
            new_methods << [new_name, param, ['warp', f - param, precond_p, precond_n, new_tasks = []]]
          end
          param += f
          new_tasks << sub
        }.replace(top)
        free.concat(top_variables)
        precond_pos.concat(top_precond_p)
        precond_not.concat(top_precond_n)
        param = old_param
      }
    }.concat(new_methods)
  end
end