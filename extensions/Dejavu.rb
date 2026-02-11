module Dejavu
  extend self

  #-----------------------------------------------
  # Apply
  #-----------------------------------------------

  def apply(operators, methods, predicates, state, tasks, goal_pos, goal_not)
    return if tasks.empty?
    methods_h = {}
    methods.each {|m| methods_h[m[0]] = m}
    knots = []
    ordered = tasks.shift
    tasks.uniq(&:first).each {|t,| visit(t, methods_h, knots)}
    tasks.unshift(ordered)
    knots.uniq! {|t,| t.object_id}
    knots.each {|task,method,decomposition|
      name = method[0]
      terms = []
      index = decomposition[-1].index {|t|
        terms |= t.drop(1)
        t.equal?(task)
      }
      terms.select! {|t| t.start_with?('?')}
      if name == task[0] && decomposition[-1].size > 1 or decomposition[1].empty? or task.size == 1 or task.drop(1).sort! != terms.sort
        name = "#{name}_#{decomposition[0]}_#{index}"
        decomposition[3] << [visited = "visited_#{name}".freeze, *terms]
        decomposition[-1].insert(index, [visit = "invisible_visit_#{name}", *terms])
        decomposition[-1].insert(index + 2, [unvisit = "invisible_unvisit_#{name}", *terms])
        unless operators.assoc(visit)
          predicates[visited] = true
          operators.push(
            [visit, terms, [], [], [[visited, *terms]], []],
            [unvisit, terms, [], [], [], [[visited, *terms]]]
          )
        end
        method.drop(2).each {|dec|
          break if dec.equal?(decomposition)
          dec[4].each {|subtask,*sterms| subtask.sub!('visit','mark') if subtask.start_with?('invisible_visit_','invisible_unvisit_') and sterms == terms}
        }
      end
    }
  end

  def visit(name, methods, knots, visited = {})
    if method = methods[name]
      (visited = visited.dup)[name] = nil
      method.drop(2).each {|decomposition| decomposition[-1].each {|task| visited.include?(name = task[0]) ? knots << [task, method, decomposition] : visit(name, methods, knots, visited)}}
    end
  end
end