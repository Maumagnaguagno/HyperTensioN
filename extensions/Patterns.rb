module Patterns
  extend self

  SWAP = 'swap_'
  DEPENDENCY = 'dependency_'
  VISIT = 'visitp' # Use 'visit' to enable caching

  #-----------------------------------------------
  # Apply
  #-----------------------------------------------

  def apply(operators, methods, predicates, state, tasks, goal_pos, goal_not, debug = false)
    # Find patterns
    puts 'Patterns'.center(50,'-'), 'Identify patterns' if debug
    match_patterns(swaps = {}, dependencies = {}, operators, predicates, debug)
    # Compose methods
    puts 'Compose methods' if debug
    compose_swap_methods(swaps, operators, methods, predicates, debug)
    compose_dependency_methods(swaps, dependencies, operators, methods, predicates, debug)
    # Build HTN
    goal_methods = find_goal_methods(operators, methods, predicates, goal_pos, goal_not, debug)
    inject_method_dependencies(swaps, methods, predicates, debug)
    add_tasks(goal_methods, operators, methods, predicates, tasks, goal_pos, goal_not, debug)
  end

  #-----------------------------------------------
  # Match patterns
  #-----------------------------------------------

  def match_patterns(swaps, dependencies, operators, predicates, debug)
    # TODO support negative patterns
    operators.each {|op|
      precond_pos, constraints = op[2].partition {|pre,| predicates[pre]}
      #precond_not = op[3].select {|pre,| predicates[pre]}
      effect_add = op[4]
      effect_del = op[5]
      # Swap (+- => -+) or (-+ => +-) or (+? => -+) or (?- => -+)
      (precond_pos & effect_del).each {|pre|
        if pre2 = effect_add.assoc(pre.first)
          cparam = pre - pre2 | pre2 - pre
          # At least one constraint must exist
          unless (pre_constraints = constraints.select {|i| (cparam - i).empty?}).empty?
            (swaps[op] ||= []) << [pre, pre_constraints]
          end
        end
      }
    }
    operators.each {|op|
      precond_pos = op[2].select {|pre,| predicates[pre]}
      #precond_not = op[3].select {|pre,| predicates[pre]}
      effect_add = op[4]
      effect_del = op[5]
      # Dependency
      swap_op = swaps[op]
      operators.each {|op2|
        # Avoid same operator, same swap or operator with effect nullified
        next if op.equal?(op2) or
          (swap_op and swap_op2 = swaps[op2] and swap_op.any? {|i,| swap_op2.assoc(i)}) or
          ((effect_add - op2[2]).empty? and (effect_del - op2[3]).empty?)
        pos = precond_pos.select {|pre,| op2[4].assoc(pre)}
        neg = [] #precond_not.select {|pre| op2[5].assoc(pre.first)}
        (dependencies[op] ||= []) << [op2, pos, neg] unless pos.empty? and neg.empty?
      }
    }
    return unless debug
    sep = ' '
    hyphen = '-'
    underscore = '_'
    edges = []
    swaps.each {|op,pre_constraints|
      namesub = (name = op.first).tr(hyphen, underscore)
      pre_constraints.each {|pre,constraints|
        edges << "\n  #{namesub} -> \"(#{pre_join = pre.join(sep)})\" [dir=both style=dashed]"
        puts "  #{name} swaps (#{pre_join}) with constraint (#{constraints.join(sep)})"
      }
    }
    dependency_counter = 0
    dependencies.each {|op,op_dependencies|
      namesub = (name = op.first).tr(hyphen, underscore)
      op_dependencies.each {|op2,pos,neg|
        dependency_counter += pos.size + neg.size
        op2_namesub = (name2 = op2.first).tr(hyphen, underscore)
        pos.each {|pre|
          puts "  #{name2} before #{name}, dependency (#{pre_join = pre.join(sep)})"
          edges.push("\n  #{op2_namesub} -> \"(#{pre_join})\"", "\n  \"(#{pre_join})\" -> #{namesub}")
        }
        neg.each {|pre|
          puts "  #{name2} before #{name}, dependency (not (#{pre_join = pre.join(sep)}))"
          edges.push("\n  #{op2_namesub} -> \"(not (#{pre_join}))\"", "\n  \"(not (#{pre_join}))\" -> #{namesub}")
        }
      }
    }
    puts 'Counter', "  Swaps: #{swaps.size}", "  Dependencies: #{dependency_counter}"
    edges.uniq!
    graph = 'digraph Patterns {'
    operators.each {|op| graph << "\n  #{op.first.tr(hyphen, underscore)} [label=\"#{op.first}(#{op[1].join(sep)})\" shape=box]"}
    puts 'DOT output', graph << edges.join << "\n}"
  end

  #-----------------------------------------------
  # Fill goal methods
  #-----------------------------------------------

  def fill_goal_methods(goal_methods, goal_pos, goal_not, source_parameters, source_pos, source_not, met, parameters)
    goal_pos.each {|goal|
      group = source_pos.assoc(goal.first)
      goal_methods[[true, goal]] << [met, group.map {|var| (i = source_parameters.index(var)) ? parameters[i] : var}] if group
    }
    goal_not.each {|goal|
      group = source_not.assoc(goal.first)
      goal_methods[[false, goal]] << [met, group.map {|var| (i = source_parameters.index(var)) ? parameters[i] : var}] if group
    }
  end

  #-----------------------------------------------
  # Find goal methods
  #-----------------------------------------------

  def find_goal_methods(operators, methods, predicates, goal_pos, goal_not, debug)
    puts 'Goals' if debug
    # Avoid methods for simple goals
    goal_pos_complex = goal_pos.reject {|goal,|
      operators.any? {|op|
        op[4].assoc(goal) and op[2].none? {|pre,| predicates[pre]} and ((precond_not = op[3].select {|pre,| predicates[pre]}).empty? or (precond_not.size == 1 and precond_not.first.first == goal))
      }
    }
    goal_not_complex = goal_not.reject {|goal,|
      operators.any? {|op|
        op[5].assoc(goal) and op[3].none? {|pre,| predicates[pre]} and ((precond_pos = op[2].select {|pre,| predicates[pre]}).empty? or (precond_pos.size == 1 and precond_pos.first.first == goal))
      }
    }
    # Find every method that contains a relevant action in the subtasks
    goal_methods = Hash.new {|h,k| h[k] = []}
    methods.each {|met|
      met.drop(2).each {|dec|
        # Use empty subtask preconditions (recursive swap)
        if dec[4].empty?
          fill_goal_methods(goal_methods, goal_pos_complex, goal_not_complex, dec[1], dec[2], dec[3], met, dec)
        else
          dec[4].each {|subtask|
            op = operators.assoc(subtask.first)
            fill_goal_methods(goal_methods, goal_pos_complex, goal_not_complex, dec[1], op[4], op[5], met, subtask.drop(1)) if op
          }
        end
      }
    }
    goal_methods.each {|(type,goal),v|
      v.uniq!
      for_goal = "_#{goal.first}"
      # Give priority based on operator relevance to goal
      v.sort_by! {|mets,|
        # Prefer to match goal
        val = mets.first.end_with?(for_goal) ? -1 : 0
        val - mets.drop(2).count {|dec| dec[4][0] and op = operators.assoc(dec[4].last.first) and op[type ? 4 : 5].assoc(goal.first)}
      }
      if debug
        puts "  #{'not ' unless type}(#{goal.join(' ')})"
        v.each {|met,pred| puts "    #{met.first}(#{met[1].join(' ')}) achieves (#{pred.join(' ')})"}
      end
    }
  end

  #-----------------------------------------------
  # Inject method dependencies
  #-----------------------------------------------

  def inject_method_dependencies(swaps, methods, predicates, debug)
    # Inject dependencies
    puts 'Inject dependencies' if debug
    methods.each {|met|
      if met.first =~ /^dependency_([\w-]+)_before_([\w-]+)_for_([\w-]+)$/
        dependency = $1
        dependent = $2
        pred = $3
        # Prefer dependency with same predicate goal
        sub = nil
        methods.each {|met2|
          if met2.first =~ /^dependency_(?!#{dependent})[\w-]+_before_#{dependency}_for_([\w-]+)$/
            sub = met2
            break if $1 == pred
          end
        }
        if sub
          puts "  #{dependency} to #{sub.first} in #{met.first}" if debug
          met.drop(3).each {|dec| dec[4][0] = [sub[0], *sub[1]] if dec[4][0].first == dependency}
          sub = nil
        end
        # Prefer dependency with same predicate goal
        methods.each {|met2|
          if not met.equal?(met2) and met2.first =~ /^dependency_swap_[\w-]+_until_[\w-]+_before_#{dependent}_for_([\w-]+)$/
            sub = met2
            break if $1 == pred
          end
        }
        if sub
          puts "  #{dependent} to #{sub.first} in #{met.first}" if debug
          dependent_split = dependent.split('_or_')
          met.drop(3).each {|dec|
            dec[4].map! {|subtask| dependent_split.include?(subtask.first) ? [sub[0], *sub[1]] : subtask}
          }
        end
      end
    }
  end

  #-----------------------------------------------
  # Add tasks
  #-----------------------------------------------

  def add_tasks(goal_methods, operators, methods, predicates, tasks, goal_pos, goal_not, debug)
    # Add tasks as unordered
    tasks[0] = false
    # Select task
    puts 'Goal to Task' if debug
    tasks_goals = []
    goal_methods.each {|(type,goal),v|
      puts "  #{'not ' unless type}(#{goal.join(' ')})" if debug
      # Ground
      if v.none? {|met,pred|
        # TODO check free variable names in pred
        ground = met[1].map {|var| (i = pred.index(var)) ? goal[i] : var}
        if ground.none? {|var| var.start_with?('?')}
          puts "    Ground task #{met.first}(#{ground.join(' ')})" if debug
          tasks_goals.unshift([ground.unshift(met.first), type, goal])
        end
      }
        # Lifted
        met, pred = v.first
        ground = met[1].map {|var| (i = pred.index(var)) ? goal[i] : var}
        puts "    Lifted task #{met.first}(#{ground.join(' ')})" if debug
        tasks_goals.unshift([compose_unification_method(operators, methods, predicates, met, ground), type, goal])
      end
    }
    # Goal primitives
    goal_pos.each {|goal|
      operators.each {|op|
        if group = op[4].assoc(goal.first)
          # TODO add unification method when required
          tasks_goals.unshift([op[1].map {|var| (i = group.index(var)) ? goal[i] : var}.unshift(op.first), true, goal])
          break
        end
      } unless goal_methods.include?([true, goal])
    }
    goal_not.each {|goal|
      operators.each {|op|
        if group = op[5].assoc(goal.first)
          # TODO add unification method when required
          tasks_goals.unshift([op[1].map {|var| (i = group.index(var)) ? goal[i] : var}.unshift(op.first), false, goal])
          break
        end
      } unless goal_methods.include?([false, goal])
    }
    ordered_tasks = []
    Knoblock.create_hierarchy(operators, predicates).each {|order|
      order = [order] unless order.first.instance_of?(Array)
      order.each {|i| i[1] = i[1].first}
      tasks_goals.reject! {|met,type,goal| ordered_tasks.unshift(met) if order.include?([type, goal.first])}
      break if tasks_goals.empty?
    }
    tasks.concat(ordered_tasks)
  end

  #-----------------------------------------------
  # Compose swap methods
  #-----------------------------------------------

  def compose_swap_methods(swaps, operators, methods, predicates, debug)
    # Method arguments
    current = '?current'
    intermediate = '?intermediate'
    swap_predicates = Hash.new {|h,k| h[k] = []}
    swaps.each {|op,pre_constraints| pre_constraints.each {|pre,constraints| swap_predicates[pre] << [op, constraints]}}
    swap_predicates.each {|(predicate_name,*predicate_terms),swap_ops|
      # Explicit or implicit agent
      agent = predicate_terms.first if predicate_terms.size != 1
      original_current = predicate_terms.last
      # Add visit and unvisit operators and predicate
      visited = "visited_#{predicate_name}"
      visit = "invisible_#{VISIT}_#{predicate_name}"
      unvisit = "invisible_un#{VISIT}_#{predicate_name}"
      unless operators.assoc(visit)
        predicates[visited] = true
        operators.push(
          [visit, predicate_terms, [], [], [[visited, *predicate_terms]], []],
          [unvisit, predicate_terms, [], [], [], [[visited, *predicate_terms]]]
        )
      end
      # Swap for each possible goal
      effects = []
      swap_ops.each {|op,| effects.concat(op[4])}
      effects.uniq!
      swap_ops.each {|op,constraints|
        original_intermediate = (constraints.first - [original_current]).last
        predicate_terms2 = predicate_terms.map {|i| i == original_current ? original_intermediate : i}
        # Add swap recursion
        free_variables = Hash.new {|h,k| h[k] = k}
        free_variables[original_current] = current
        free_variables[original_intermediate] = intermediate
        precond_pos = constraints.map {|c| c.map {|i| i.start_with?('?') ? free_variables[i] : i}}.unshift(agent ? [predicate_name, agent, current] : [predicate_name, current])
        precond_not = [
          [predicate_name, *predicate_terms2],
          agent ? [visited, agent, intermediate] : [visited, intermediate]
        ]
        # Replace signature with free variables
        new_op = op[1].map {|i| i == agent ? i : free_variables[i]}.unshift(op.first)
        free_variables = free_variables.values
        effects.each {|eff|
          # Swap method
          unless swap_method = methods.assoc(method_name = "swap_#{predicate_name}_until_#{eff.first}")
            puts "  swap method composed: #{method_name}" if debug
            methods << swap_method = [method_name, predicate_terms2]
            if (predicate_terms2 - eff).empty?
              swap_method << ['base', [], [eff], [], []]
            else
              eff = [*constraints, eff]
              swap_method << ['base', eff.flatten(1).select! {|i| i.start_with?('?') and not predicate_terms2.include?(i)}.uniq, eff, [], []]
            end
          end
          # Label and free variables
          swap_method << ["using_#{op.first}", free_variables,
            # Positive preconditions
            precond_pos,
            # Negative preconditions
            precond_not,
            # Subtasks
            agent ? [
              new_op,
              [visit, agent, current],
              [method_name, *predicate_terms2],
              [unvisit, agent, current]
            ] : [
              new_op,
              [visit, current],
              [method_name, *predicate_terms2],
              [unvisit, current]
            ]
          ]
        }
      }
    }
  end

  #-----------------------------------------------
  # Compose dependency methods
  #-----------------------------------------------

  def compose_dependency_methods(swaps, dependencies, operators, methods, predicates, debug)
    visited = []
    disjunctions = Hash.new {|h,k| h[k] = []}
    dependencies.each_key {|op| disjunctions[[op[4], op[5]]] << op}.each {|op,op_dependencies|
      next if visited.include?(op)
      second_terms = op[1]
      seconds = disjunctions[[op[4], op[5]]].select {|op2| second_terms == op2[1] and op_dependencies == dependencies[op2]}
      visited.concat(seconds)
      # Cluster operators to compose methods
      op_dependencies.each {|first,pos,neg|
        # TODO consider all dependencies
        type = true
        pre = pos.first
        # Dependency of dependency
        first_terms = first[1]
        swaps[first]&.each {|p,|
          if m = methods.assoc("swap_#{p.first}_until_#{p.first}")
            first = m
            if p.first == pre.first
              first_terms = pre.drop(1)
              break
            else first_terms = p.drop(1)
            end
          end
        } or swaps[op]&.each {|p,|
          if m = methods.assoc("swap_#{p.first}_until_#{p.first}")
            seconds = [m]
            if p.first == pre.first
              second_terms = pre.drop(1)
              break
            else second_terms = p.drop(1)
            end
          end
        }
        name = "dependency_#{first.first}_before_#{seconds.map(&:first).join('_or_')}"
        next if methods.any? {|met,| met.start_with?(name)}
        precond_pos = []
        precond_not = []
        replacements = {}
        if operators.include?(first)
          fill_preconditions(first, predicates, precond_pos, precond_not, first_terms)
          # Replace different variables between first and second
          pre.zip(first[type ? 4 : 5].assoc(pre.first)) {|a,b|
            if a != b
              replacements[a] = b
              replacements[b] ||= a
            end
          }
        end
        satisfied = []
        unsatisfied = []
        seconds.each {|second|
          # Preconditions
          precond_pos_second = []
          precond_not_second = []
          fill_preconditions(second, predicates, precond_pos_second, precond_not_second, second_terms) if operators.include?(second)
          precond_pos_first = precond_pos_second | precond_pos
          precond_not_first = precond_not_second | precond_not
          # Label and free variables
          satisfied << [seconds.size == 1 ? 'satisfied' : "satisfied_#{second.first}", [],
            # Positive preconditions
            type ? precond_pos_second << pre : precond_pos_second,
            # Negative preconditions
            type ? precond_not_second : precond_not_second << pre,
            # Subtasks
            [[second.first, *second_terms]]
          ] unless first.first.start_with?(SWAP)
          # Label and free variables
          unsatisfied << [seconds.size == 1 ? 'unsatisfied' : "unsatisfied_#{second.first}", [],
            # Positive preconditions
            type ? precond_pos_first : precond_pos_first << pre,
            # Negative preconditions
            type ? precond_not_first << pre : precond_not_first,
            # Subtasks
            [
              first_terms.map {|i| replacements[i] || i}.unshift(first.first),
              [second.first, *second_terms]
            ]
          ]
        }
        # Disjunctions share effects
        op[4].each {|effect|
          puts "  dependency method composed: #{name}_for_#{effect.first}" if debug
          methods << ["#{name}_for_#{effect.first}", first_terms | second_terms,
            # Label and free variables
            ['goal-satisfied', [],
              # Positive preconditions
              [effect],
              # Negative preconditions
              [],
              # Subtasks
              []
            ],
            *satisfied,
            *unsatisfied
          ]
        }
      }
    }
  end

  #-----------------------------------------------
  # Compose unification method
  #-----------------------------------------------

  def compose_unification_method(operators, methods, predicates, met, substitutions)
    # Split free variables from ground terms
    free = []
    ground_sub = []
    ground_var = []
    substitutions.zip(met[1]) {|sub,m|
      if sub.start_with?('?')
        free << sub
      else
        ground_sub << sub
        ground_var << m
      end
    }
    unless methods.assoc(name = "unify#{free.join.tr!('?','_')}_before_#{met.first}")
      # Find rigid predicates shared across decompositions to act as preconditions
      precond_pos = []
      precond_not = []
      met.drop(3).each {|dec|
        if dec.first.start_with?('unsatisfied', 'using_')
          fill_preconditions(dec, predicates, precond_pos_local = [], precond_not_local = [], met[1])
          precond_pos.empty? ? precond_pos = precond_pos_local : precond_pos &= precond_pos_local
          precond_not.empty? ? precond_not = precond_not_local : precond_not &= precond_not_local
        end
      }
      # Find other preconditions to bind free variables at run-time
      bind_variables(free, met, ground_var, precond_pos, operators, methods)
      methods << [name, ground_var,
        # Label and free variables
        [free.join('_').delete!('?'), free,
          # Positive preconditions
          precond_pos,
          # Negative preconditions
          precond_not,
          # Subtasks
          [[met[0], *met[1]]]
        ]
      ]
    end
    ground_sub.unshift(name)
  end

  #-----------------------------------------------
  # Bind variables
  #-----------------------------------------------

  def bind_variables(free, root, ground_var, precond_pos, operators, methods)
    new_free = []
    visited = {}
    free.each {|f|
      if precond_pos.none? {|pre| pre.include?(f)}
        # DFS
        fringe = [root]
        visited.clear
        while node = fringe.shift
          visited[node.first] = true
          if operators.assoc(node.first)
            break if node[2].any? {|pre|
              if pre.include?(f) and not precond_pos.assoc(pre.first)
                precond_pos << pre
                new_free.concat(pre.drop(1).reject! {|i| ground_var.include?(i) or free.include?(i)})
              end
            }
          elsif node.first.start_with?(DEPENDENCY, SWAP)
            # TODO fix new multiple unsatisfied dependencies and multiple swap operators over same predicate
            node.last[4].reverse_each {|i,| fringe.unshift(operators.assoc(i) || methods.assoc(i)) unless visited.include?(i)}
          # TODO else support user provided methods
          end
        end
      end
    }
    new_free.uniq!
    free.concat(new_free)
  end

  #-----------------------------------------------
  # Fill preconditions
  #-----------------------------------------------

  def fill_preconditions(operator, predicates, precond_pos, precond_not, variables)
    operator[2].each {|pre| precond_pos << pre if not predicates[pre.first] and pre.size == 1 || variables.any? {|i| pre.include?(i)}}
    operator[3].each {|pre| precond_not << pre if not predicates[pre.first] and pre.size == 1 || variables.any? {|i| pre.include?(i)}}
  end
end