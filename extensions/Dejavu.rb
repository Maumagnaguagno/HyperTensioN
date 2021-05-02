module Dejavu
  extend self

  #-----------------------------------------------
  # Apply
  #-----------------------------------------------

  def apply(operators, methods, predicates, state, tasks, goal_pos, goal_not, debug = false)
    return if tasks.empty?
    knots = []
    ordered = tasks.shift
    tasks.uniq(&:first).each {|t| visit(t.first, methods, knots)}
    tasks.unshift(ordered)
    knots.uniq!
    knots.each {|name,decomposition,index|
      terms = decomposition.last.first(index + 1).inject([]) {|s,i| s | i.drop(1)}
      if decomposition[1].empty? or decomposition.last[index].size == 1 or decomposition.last[index].drop(1).sort! != terms.sort
        name = "#{name}_#{decomposition.first}_#{index}"
        decomposition[3] << [visited = "visited_#{name}".freeze, *terms]
        decomposition.last.insert(index, [visit = "invisible_visit_#{name}", *terms])
        decomposition.last.insert(index + 2, [unvisit = "invisible_unvisit_#{name}", *terms])
        unless operators.assoc(visit)
          predicates[visited] = true
          operators.push(
            [visit, terms, [], [], [[visited, *terms]], []],
            [unvisit, terms, [], [], [], [[visited, *terms]]]
          )
        end
      end
    }
  end

  def visit(method, methods, knots, visited = {})
    if visited.include?(method) then true
    elsif method = methods.assoc(method)
      visited[method.first] = nil
      method.drop(2).each {|decomposition| decomposition.last.each_with_index {|task,index| knots << [method.first, decomposition, index] if task.first != method.first and visit(task.first, methods, knots, visited.dup)}}
      false
    end
  end
end