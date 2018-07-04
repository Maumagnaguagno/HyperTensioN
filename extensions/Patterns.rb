module Patterns
  extend self

  SWAP_PREFIX = 'swap_'
  DEPENDENCY_PREFIX = 'dependency_'

  #-----------------------------------------------
  # Apply
  #-----------------------------------------------

  def apply(operators, methods, predicates, state, tasks, goal_pos, goal_not, debug = false, negative_patterns = false, dot = false)
    # Find patterns
    puts 'Patterns'.center(50,'-'), 'Identify patterns' if debug
    swaps = {}
    dependencies = {}
    output = match_patterns(swaps, dependencies, operators, predicates, debug, negative_patterns)
    # Compose methods
    if debug
      puts 'DOT output', output if dot
      puts 'Compose methods'
    end
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

  def match_patterns(swaps, dependencies, operators, predicates, debug, negative_patterns)
    sep = ' '
    hyphen = '-'
    underscore = '_'
    edges = []
    swap_counter = dependency_counter = 0
    operators.each {|op|
      name = op.first
      namesub = name.tr(hyphen, underscore)
      precond_pos, constraints = op[2].partition {|pre| predicates[pre.first]}
      #precond_not = op[3].select {|pre| predicates[pre.first]}
      effect_add = op[4]
      effect_del = op[5]
      # Swap (+- => -+) or (-+ => +-) or (+? => -+) or (?- => -+)
      (precond_pos & effect_del).each {|pre|
        if pre2 = effect_add.assoc(pre.first)
          cparam = (pre.drop(1) - pre2.drop(1)) | (pre2.drop(1) - pre.drop(1))
          # TODO constraint may not exist or exist more than once
          if constraint = constraints.find {|i| (cparam - i).empty?}
            swaps[op] = [pre, constraint]
            if debug
              swap_counter += 1
              puts "  #{name} swaps (#{pre_join = pre.join(sep)}) with constraint (#{constraint.join(sep)})"
              edges << "\n  #{namesub} -> \"(#{pre_join})\" [dir=both style=dashed]"
            end
            break
          end
        end
      }
    }
    operators.each {|op|
      name = op.first
      namesub = name.tr(hyphen, underscore)
      precond_pos = op[2].select {|pre| predicates[pre.first]}
      precond_not = op[3].select {|pre| predicates[pre.first]}
      effect_add = op[4]
      effect_del = op[5]
      # TODO support negative swaps (if negative_patterns)
      # Dependency
      swap_op = swaps[op]
      operators.each {|op2|
        # Dependency cannot happen between related swap operators
        if swap_op
          swap_op2 = swaps[op2]
          next if swap_op2 and swap_op.first == swap_op2.first
        end
        # TODO check mutex relations
        # Avoid same operator or operator with effect nullified
        next if op.equal?(op2) or ((effect_add - op2[2]).empty? and (effect_del - op2[3]).empty?)
        op2_namesub = op2.first.tr(hyphen, underscore)
        precond_pos.each {|pre|
          if op2[4].assoc(pre.first)
            (dependencies[op] ||= []) << [op2, true, pre]
            next unless debug
            dependency_counter += 1
            puts "  #{op2.first} before #{name}, dependency (#{pre_join = pre.join(sep)})"
            edges.push("\n  #{op2_namesub} -> \"(#{pre_join})\"", "\n  \"(#{pre_join})\" -> #{namesub}")
          end
        }
        next unless negative_patterns
        precond_not.each {|pre|
          if op2[5].assoc(pre.first)
            (dependencies[op] ||= []) << [op2, false, pre]
            next unless debug
            dependency_counter += 1
            puts "  #{op2.first} before #{name}, dependency (not (#{pre_join = pre.join(sep)}))"
            edges.push("\n  #{op2_namesub} -> \"(not (#{pre_join}))\"", "\n  \"(not (#{pre_join}))\" -> #{namesub}")
          end
        }
      }
    }
    return unless debug
    puts 'Counter', "  Swaps: #{swap_counter}", "  Dependency: #{dependency_counter}"
    edges.uniq!
    graph = 'digraph Patterns {'
    operators.each {|op| graph << "\n  #{op.first.tr(hyphen, underscore)} [label=\"#{op.first}(#{op[1].join(sep)})\" shape=box]"}
    graph << "\n#{edges.join}\n}"
  end

  #-----------------------------------------------
  # Fill goal tasks
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
    goal_pos_complex = goal_pos.reject {|goal|
      operators.any? {|op|
        precond_not = op[3].select {|pre| predicates[pre.first]}
        op[4].assoc(goal.first) and op[2].none? {|pre| predicates[pre.first]} and (precond_not.empty? or (precond_not.size == 1 and precond_not.first.first == goal.first))
      }
    }
    goal_not_complex = goal_not.reject {|goal|
      operators.any? {|op|
        precond_pos = op[2].select {|pre| predicates[pre.first]}
        op[5].assoc(goal.first) and op[3].none? {|pre| predicates[pre.first]} and (precond_pos.empty? or (precond_pos.size == 1 and precond_pos.first.first == goal.first))
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
      for_goal = "_for_#{goal.first}"
      until_goal = "_until_#{goal.first}"
      # Give priority based on operator relevance to goal
      v.sort_by! {|mets,pred2|
        # Prefer to match goal
        val = mets.first.end_with?(for_goal) || mets.first.end_with?(until_goal) ? -1 : 0
        val - mets.drop(2).count {|dec| !dec[4].empty? and op = operators.assoc(dec[4].last.first) and op[type ? 4 : 5].assoc(goal.first)}
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
      # TODO apply to any method
      if met.first =~ /^dependency_([\w-]+)_before_([\w-]+)_for_([\w-]+)$/
        dependency = $1
        dependent = $2
        pred = $3
        # Prefer dependency with same predicate goal
        sub = nil
        methods.each {|met2|
          if met2.first =~ /^dependency_(?!#{dependent})[\w-]+_before_#{dependency}_for_([\w-]+)$/
            if $1 == pred
              sub = met2
              break
            else sub ||= met2
            end
          end
        }
        if sub
          puts "  #{met.last[4][0].first} to #{sub.first} in #{met.first}" if debug
          met.last[4][0] = sub.first(2).flatten
          # Fill missing variables and preconditions related
          met.last[1].concat(new_variables = sub[1] - met[1])
          fill_preconditions(sub[2], predicates, met.last[2], met.last[3], new_variables)
          # TODO add unification if any variable is still free
          sub = nil
        end
        # Prefer dependency with same predicate goal
        methods.each {|met2|
          if met != met2 and met2.first =~ /^dependency_swap_[\w-]+_until_[\w-]+_before_#{dependent}_for_([\w-]+)$/
            if $1 == pred
              sub = met2
              break
            else sub ||= met2
            end
          end
        }
        if sub
          puts "  #{met[3][4][0].first} to #{sub.first} in #{met.first}" if debug
          if met[4]
            met[3][4][0] = met[4][4][1] = sub.first(2).flatten
          else
            met[3][4][0] = sub.first(2).flatten
          end
          # TODO fill preconditions
        end
=begin
        if sub = swaps.find {|op,_| op.first == dependent}
          # TODO how to deal with swap here?
          # - remove constraint precondition
          # - remove current parameter, which may require to scan all other methods
          met[3][4][0] = met[4][4][1] = ?
        end
=end
      end
    }
  end

  #-----------------------------------------------
  # Add tasks
  #-----------------------------------------------

  def add_tasks(goal_methods, operators, methods, predicates, tasks, goal_pos, goal_not, debug)
    # TODO Interference topological sort to avoid unordered tasks
    # Add tasks as unordered
    tasks[0] = false if tasks.empty? or tasks.first
    # Select task
    puts 'Goal to Task' if debug
    goal_methods.each {|(type,goal),v|
      puts "  #{'not ' unless type}(#{goal.join(' ')})" if debug
      # Ground
      ground_task = false
      v.each {|met,pred|
        # TODO check free variable names in pred
        ground = met[1].map {|var| (i = pred.index(var)) ? goal[i] : var}
        if ground.none? {|var| var.start_with?('?')}
          puts "    Ground task #{met.first}(#{ground.join(' ')})" if debug
          tasks << ground.unshift(met.first)
          ground_task = true
          break
        end
      }
      # Lifted
      unless ground_task
        met, pred = v.first
        ground = met[1].map {|var| (i = pred.index(var)) ? goal[i] : var}
        puts "    Lifted task #{met.first}(#{ground.join(' ')})" if debug
        tasks << compose_unification_method(operators, methods, predicates, met, ground)
      end
    }
    # Goal primitives
    goal_pos.each {|goal|
      next if goal_methods.include?([true, goal])
      operators.each {|op|
        if group = op[4].assoc(goal.first)
          # TODO add unification method when required
          tasks << op[1].map {|var| (i = group.index(var)) ? goal[i] : var}.unshift(op.first)
          break
        end
      }
    }
    goal_not.each {|goal|
      next if goal_methods.include?([false, goal])
      operators.each {|op|
        if group = op[5].assoc(goal.first)
          # TODO add unification method when required
          tasks << op[1].map {|var| (i = group.index(var)) ? goal[i] : var}.unshift(op.first)
          break
        end
      }
    }
    tasks.uniq!
  end

  #-----------------------------------------------
  # Compose swap methods
  #-----------------------------------------------

  def compose_swap_methods(swaps, operators, methods, predicates, debug)
    # Method arguments
    current = '?current'
    intermediate = '?intermediate'
    swap_predicates = Hash.new {|h,k| h[k] = []}
    swaps.each {|op,m| swap_predicates[m.first] << [op, m.last]}
    swap_predicates.each {|predicate,swap_ops|
      predicate_name, *predicate_terms = predicate
      # Explicit or implicit agent
      agent = predicate_terms.first if predicate_terms.size != 1
      # Add visit and unvisit operators and predicate
      visited = "visited_#{predicate_name}"
      visit = "invisible_visit_#{predicate_name}"
      unvisit = "invisible_unvisit_#{predicate_name}"
      unless operators.assoc(visit)
        predicates[visited] = true
        operators.push([visit, predicate_terms, [], [], [[visited, *predicate_terms]], []],
          [unvisit, predicate_terms, [], [], [], [[visited, *predicate_terms]]])
      end
      # Swap for each possible goal
      effects = []
      swap_ops.each {|op,constraint|
        # Parameters index
        # TODO better support of predicate terms
        original_current = (predicate_terms - [agent]).last
        original_intermediate = (constraint - [original_current]).last
        predicate_terms2 = predicate_terms.map {|i| i == original_current ? original_intermediate : i}
        op[4].each {|eff|
          next if effects.include?(eff_name = eff.first)
          effects << eff_name
          method_name = "swap_#{predicate_name}_until_#{eff_name}"
          # Swap method
          unless swap_method = methods.assoc(method_name)
            puts "  swap method composed: #{method_name}" if debug
            methods << swap_method = [method_name, predicate_terms2, ['base', [], [eff], [], []]]
          end
          # Add swap recursion
          swap_ops.each {|op2,constraint2|
            constraint_terms = Array.new(constraint2.size - 3) {|i| "?middle_#{i}"}
            constraint_terms.unshift(current) << intermediate
            constraint_terms.reverse! if original_current == constraint2.last
            # Replace op2 signature with new variables
            new_op2 = op2[1].map {|var| var == original_current ? current : var == original_intermediate ? intermediate : var}.unshift(op2.first)
            # Label and free variables
            swap_method << ["using_#{op2.first}", constraint_terms,
              # Positive preconditions
              [
                agent ? [predicate_name, agent, current] : [predicate_name, current],
                [constraint2.first, *constraint_terms]
                # TODO check other preconditions
              ],
              # Negative preconditions
              [
                [predicate_name, *predicate_terms2],
                agent ? [visited, agent, intermediate] : [visited, intermediate]
              ],
              # Subtasks
              agent ? [
                new_op2,
                [visit, agent, current],
                [method_name, *predicate_terms2],
                [unvisit, agent, current]
              ] : [
                new_op2,
                [visit, current],
                [method_name, *predicate_terms2],
                [unvisit, current]
              ]
            ]
          }
        }
      }
    }
  end

  #-----------------------------------------------
  # Compose dependency methods
  #-----------------------------------------------

  def compose_dependency_methods(swaps, dependencies, operators, methods, predicates, debug)
    # Operator relevance
    relevance = Hash.new(0)
    dependencies.each {|second,met| relevance[second.first] = met.uniq {|i| i.first}.size}
    swaps.each {|op,_| relevance[op.first] = 1}
    operators.sort_by {|op| relevance[op.first]}.each {|op|
      op_dependencies = dependencies[op]
      next unless op_dependencies
      # Cluster operators to compose methods
      if op_dependencies.size == 1
        first_dep, type_dep, pre_dep = op_dependencies.first
        compose_dependency_method(first_dep, op, type_dep, pre_dep, swaps, operators, methods, predicates, debug)
      else
        op_dependencies.sort_by! {|i| relevance[i.first]}.each {|first,type,pre|
          compose_dependency_method(first, op, type, pre, swaps, operators, methods, predicates, debug)
        }
        next unless debug
        # Sort dependencies
        same_dependency_predicate = {}
        swap_dependencies = []
        op_dependencies.sort_by! {|i| relevance[i.first]}.each {|first,type,pre|
          if swaps.include?(first)
            compose_dependency_method(first, op, type, pre, swaps, operators, methods, predicates, debug)
            swap_dependencies << [first, type, pre]
          else (same_dependency_predicate[[type,pre]] ||= []) << first
          end
        }
        # Operators related to the same dependency generate an OR method, otherwise generate AND method
        puts "  #{op.first} requires a complex method\n    (and"
        same_dependency_predicate.each {|(type,pre),list_of_op|
          list_of_op.each {|op_first|
            compose_dependency_method(op_first, op, type, pre, swaps, operators, methods, predicates, debug)
            if list_of_op.size != 1
              puts '      (or'
              indentation = '        '
            else indentation = '      '
            end
            puts "#{indentation}#{op_name = op_first.first} achieves (#{type ? pre.join(' ') : "not (#{pre.join(' ')})"})"
            methods.each {|met| puts "#{indentation}  consider to use method #{met.first}" if met.first =~ /^dependency_[\w-]+_before_#{op_name}$/o}
          }
          puts '      )' if list_of_op.size != 1
        }
        # Swaps must happen at the end of every branch ((op1 OR op2) AND op_swap AND op)
        swap_dependencies.each {|op_swap,type,pre|
          puts "      #{op_swap.first} achieves (#{type ? pre.join(' ') : "not (#{pre.join(' ')})"})"
          methods.each {|met| puts "        consider to use method #{met.first}" if met.first =~ /^swap_[\w-]+_until_#{pre.first}$/o}
        }
        puts "      #{op.first}\n    )"
      end
    }
  end

  #-----------------------------------------------
  # Compose dependency method
  #-----------------------------------------------

  def compose_dependency_method(first, second, type, pre, swaps, operators, methods, predicates, debug)
    # Dependency of dependency
    first_terms = first[1]
    if m = swaps[first]
      first = methods.assoc("swap_#{m.first.first}_until_#{m.first.first}")
      first_terms = pre.drop(1) if pre.first == m.first.first
    end
    second_effects = second[4]
    second_terms = second[1]
    if m = swaps[second]
      second = methods.assoc("swap_#{m.first.first}_until_#{m.first.first}")
      second_terms = pre.drop(1) if pre.first == m.first.first
    end
    name = "dependency_#{first.first}_before_#{second.first}"
    return if methods.any? {|met| met.first.start_with?(name)}
    # Preconditions
    (variables = first_terms + second_terms).uniq!
    precond_pos_second = []
    precond_not_second = []
    fill_preconditions(second, predicates, precond_pos_second, precond_not_second, second_terms) if operators.include?(second)
    precond_pos = precond_pos_second.dup
    precond_not = precond_not_second.dup
    fill_preconditions(first, predicates, precond_pos, precond_not, variables) if operators.include?(first)
    precond_pos.uniq!
    precond_not.uniq!
    # Variables
    possible_terms = first_terms + pre
    variables = first[1].select {|i| precond_pos.any? {|pre2| pre2.include?(i)} or possible_terms.include?(i)}
    variables.concat(second_terms).uniq!
    second_effects.each {|effect|
      puts "  dependency method composed: #{name}_for_#{effect.first}" if debug
      methods << met = ["#{name}_for_#{effect.first}", variables,
        # Label and free variables
        ['goal-satisfied', [],
          # Positive preconditions
          [effect],
          # Negative preconditions
          [],
          # Subtasks
          []
        ]
      ]
      # Label and free variables
      met << ['satisfied', [],
        # Positive preconditions
        type ? precond_pos_second + [pre] : precond_pos_second,
        # Negative preconditions
        type ? precond_not_second : precond_not_second + [pre],
        # Subtasks
        [[second.first, *second_terms]]
      ] unless first.first.start_with?(SWAP_PREFIX)
      # Label and free variables
      met << ['unsatisfied', [],
        # Positive preconditions
        type ? precond_pos : precond_pos + [pre],
        # Negative preconditions
        type ? precond_not + [pre] : precond_not,
        # Subtasks
        [
          [first.first, *first_terms],
          [second.first, *second_terms]
        ]
      ]
    }
  end

  #-----------------------------------------------
  # Compose unification method
  #-----------------------------------------------

  def compose_unification_method(operators, methods, predicates, met, substitutions)
    # Split free variables from ground terms
    free, ground = substitutions.zip(met[1]).partition {|sub,var| sub.start_with?('?')}
    if ground.empty?
      ground_sub = []
      ground_var = []
    else ground_sub, ground_var = ground.transpose
    end
    unless methods.assoc(name = "unify#{free.map! {|i| i.first}.join.tr!('?','_')}_before_#{met.first}")
      # For all decompositions, find invariant predicates that act as preconditions
      precond_pos = []
      precond_not = []
      met.drop(2).each {|dec| fill_preconditions(dec, predicates, precond_pos, precond_not, met[1])}
      precond_pos.uniq!
      precond_not.uniq!
      # Find other preconditions to bind free variables at run-time
      bind_variables(free, met, ground_var, precond_pos, operators, methods)
      methods << [name, ground_var,
        # Label and free variables
        [free.join('_').delete('?'), free,
          # Positive preconditions
          precond_pos,
          # Negative preconditions
          precond_not,
          # Subtasks
          [met.first(2).flatten]
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
        until fringe.empty?
          node = fringe.shift
          visited[node.first] = true
          if operators.assoc(node.first)
            break if node[2].any? {|pre|
              if pre.include?(f) and not precond_pos.assoc(pre.first)
                precond_pos << pre
                new_free.concat(pre.drop(1).select {|i| not ground_var.include?(i) || free.include?(i)})
              end
            }
          elsif node.first.start_with?(DEPENDENCY_PREFIX) or node.first.start_with?(SWAP_PREFIX)
            node.last[4].reverse_each {|i| fringe.unshift(operators.assoc(i.first) || methods.assoc(i.first)) unless visited.include?(i.first)}
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