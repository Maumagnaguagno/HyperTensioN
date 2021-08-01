module Dejavu
  extend self

  #-----------------------------------------------
  # Apply
  #-----------------------------------------------

  def apply(operators, methods, predicates, state, tasks, goal_pos, goal_not, debug = false)
    return if tasks.empty?
    knots = []
    ordered = tasks.shift
    tasks.uniq(&:first).each {|t,| visit(t, methods, knots)}
    tasks.unshift(ordered)
    knots.uniq! {|i| i.last.object_id}
    knots.each {|method,decomposition,task|
      name = method.first
      terms = []
      index = decomposition.last.find_index {|t|
        terms |= t.drop(1)
        t.equal?(task)
      }
      if name == task.first && decomposition.last.size > 1 or decomposition[1].empty? or task.size == 1 or task.drop(1).sort! != terms.sort
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
        method.drop(2).each {|dec|
          break if dec.equal?(decomposition)
          dec.last.each {|subtask,*sterms| subtask.sub!('visit','mark') if subtask.start_with?('invisible_visit_','invisible_unvisit_') and sterms == terms}
        }
      end
    }
  end

  def visit(name, methods, knots, visited = {})
    if visited.include?(name) then true
    elsif method = methods.assoc(name)
      visited[name] = nil
      method.drop(2).each {|decomposition| decomposition.last.each {|task| knots << [method, decomposition, task] if visit(task.first, methods, knots, visited.dup)}}
      false
    end
  end
end