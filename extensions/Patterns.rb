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
          # TODO constraint may not exist in some cases
          if constraint = constraints.find {|i| i & cparam == cparam}
            swaps[op] = [pre, constraint]
            if debug
              swap_counter += 1
              pre_join = pre.join(sep)
              puts "  #{name} swaps (#{pre_join}) with constraint (#{constraint.join(sep)})"
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
        next if op.equal?(op2) or (op2[2].all? {|pre| effect_add.include?(pre)} and op2[3].all? {|pre| effect_del.include?(pre)})
        op2_namesub = op2.first.tr(hyphen, underscore)
        precond_pos.each {|pre|
          next unless op2[4].assoc(pre.first)
          (dependencies[op] ||= []) << [op2, true, pre]
          next unless debug
          dependency_counter += 1
          pre_join = pre.join(sep)
          puts "  #{op2.first} before #{name}, dependency (#{pre_join})"
          edges.push("\n  #{op2_namesub} -> \"(#{pre_join})\"", "\n  \"(#{pre_join})\" -> #{namesub}")
        }
        next unless negative_patterns
        precond_not.each {|pre|
          next unless op2[5].assoc(pre.first)
          (dependencies[op] ||= []) << [op2, false, pre]
          next unless debug
          dependency_counter += 1
          pre_join = pre.join(sep)
          puts "  #{op2.first} before #{name}, dependency (not (#{pre_join}))"
          edges.push("\n  #{op2_namesub} -> \"(not (#{pre_join}))\"", "\n  \"(not (#{pre_join}))\" -> #{namesub}")
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
      # Give priority based on operator relevance to goal
      v.sort_by! {|mets,pred2|
        # Avoid swaps
        val = mets.first.include?(SWAP_PREFIX) ? 1 : 0
        # Prefer to match goal
        val -= 1 if mets.first.end_with?(for_goal)
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
          if met2.first =~ /^dependency_([\w-]+)_before_#{dependency}_for_([\w-]+)$/ and $1 != dependent
            if $2 == pred
              sub = met2
              break
            elsif not sub
              sub = met2
            end
          end
        }
        if sub
          puts "  #{met[4][4][0].first} to #{sub.first} in #{met.first}" if debug
          met[4][4][0] = sub.first(2).flatten
          # Fill missing variables and preconditions related
          met[4][1].concat(new_variables = sub[1] - met[1])
          fill_preconditions(sub[2], predicates, met[4][2], met[4][3], new_variables)
          # TODO add unification if any variable is still free
          sub = nil
        end
        # Prefer dependency with same predicate goal
        methods.each {|met2|
          if met != met2 and met2.first =~ /^dependency_swap_[\w-]+_until_[\w-]+_before_#{dependent}_for_([\w-]+)$/
            if $1 == pred
              sub = met2
              break
            elsif not sub
              sub = met2
            end
          end
        }
        if sub
          puts "  #{met[3][4][0].first} to #{sub.first} in #{met.first}" if debug
          met[3][4][0] = met[4][4][1] = sub.first(2).flatten
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
    if tasks.empty?
      tasks << false
    elsif tasks.first
      tasks[0] = false
    end
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
          tasks << [op.first, *op[1].map {|var| (i = group.index(var)) ? goal[i] : var}]
          break
        end
      }
    }
    goal_not.each {|goal|
      next if goal_methods.include?([false, goal])
      operators.each {|op|
        if group = op[5].assoc(goal.first)
          # TODO add unification method when required
          tasks << [op.first, *op[1].map {|var| (i = group.index(var)) ? goal[i] : var}]
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
        op[4].each {|eff|
          next if effects.include?(eff_name = eff.first)
          effects << eff_name
          method_name = "swap_#{predicate_name}_until_#{eff_name}"
          # Swap method
          unless swap_method = methods.assoc(method_name)
            puts "  swap method composed: #{method_name}" if debug
            methods << swap_method = [method_name, predicate_terms.sort!,
              ['base', [], [[eff_name, *predicate_terms.first(eff.size.pred)]], [], []]]
          end
          # Add swap recursion
          swap_ops.each {|op2,constraint2|
            constraint_terms = Array.new(constraint2.size - 3) {|i| "?middle_#{i}"}
            constraint_terms.unshift(current) << intermediate
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
                predicate,
                agent ? [visited, agent, intermediate] : [visited, intermediate]
              ],
              # Subtasks
              agent ? [
                new_op2,
                [visit, agent, current],
                [method_name, *predicate_terms],
                [unvisit, agent, current]
              ] : [
                new_op2,
                [visit, current],
                [method_name, *predicate_terms],
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
        dep_first, dep_type, dep_pre = op_dependencies.first
        compose_dependency_method(dep_first, op, dep_type, dep_pre, swaps, operators, methods, predicates, debug)
      else
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
        puts "  #{op.first} requires a complex method\n    (and" if debug
        # Operators related to the same dependency generate OR method, otherwise generate AND method
        same_dependency_predicate.each {|(type,pre),list_of_op|
          if debug
            if list_of_op.size != 1
              puts '      (or'
              indentation = '        '
            else indentation = '      '
            end
          end
          list_of_op.each {|op_first|
            op_name = op_first.first
            if debug
              puts "#{indentation}#{op_name} achieves (#{type ? pre.join(' ') : "not (#{pre.join(' ')})"})"
              methods.each {|met| puts "#{indentation}  consider to use method #{met.first}" if met.first =~ /^dependency_[\w-]+_before_#{op_name}$/o}
            end
            compose_dependency_method(op_first, op, type, pre, swaps, operators, methods, predicates, false)
          }
          puts '      )' if debug and list_of_op.size != 1
        }
        next unless debug
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
    name = "dependency_#{first.first}_before_#{second.first}"
    return if methods.any? {|met| met.first.start_with?(name)}
    # Preconditions
    precond_pos = []
    precond_not = []
    (variables = first_terms + second[1]).uniq!
    fill_preconditions(first, predicates, precond_pos, precond_not, variables) if operators.include?(first)
    fill_preconditions(second, predicates, precond_pos, precond_not, variables)
    precond_pos.uniq!
    precond_not.uniq!
    # Variables
    possible_terms = first_terms + pre
    variables = first[1].select {|i| precond_pos.any? {|pre2| pre2.include?(i)} or possible_terms.include?(i)}
    variables.concat(second[1]).uniq!
    second[4].each {|effect|
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
        type ? precond_pos + [pre] : precond_pos,
        # Negative preconditions
        type ? [] : [pre],
        # Subtasks
        [second.first(2).flatten]
      ] unless first.first.start_with?(SWAP_PREFIX)
      # Label and free variables
      met << ['unsatisfied', [],
        # Positive preconditions
        type ? precond_pos : precond_pos + [pre],
        # Negative preconditions
        type ? [pre] : [],
        # Subtasks
        [
          [first.first, *first_terms],
          second.first(2).flatten
        ]
      ]
    }
  end

  #-----------------------------------------------
  # Compose unification method
  #-----------------------------------------------

  def compose_unification_method(operators, methods, predicates, met, substitutions)
    name = "unify_#{met.first}"
    # Split free variables from ground terms
    free, ground = substitutions.zip(met[1]).partition {|sub,var| sub.start_with?('?')}
    if ground.empty?
      ground_sub = []
      ground_var = []
    else ground_sub, ground_var = ground.transpose
    end
    if methods.none? {|m| m.first == name and m[1] == ground_var}
      # For all decompositions, find invariant predicates that act as preconditions
      precond_pos = []
      precond_not = []
      met.drop(2).each {|dec| fill_preconditions(dec, predicates, precond_pos, precond_not, met[1])}
      precond_pos.uniq!
      precond_not.uniq!
      # Find other preconditions to bound free variables at run-time
      bind_variables(free.map! {|i| i.first}, met, ground_var, precond_pos, precond_not, operators, methods)
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

  def bind_variables(free, root, ground_var, precond_pos, precond_not, operators, methods)
    new_free = []
    free.each {|f|
      unless precond_pos.any? {|pre| pre.include?(f)}
        # DFS
        fringe = [root]
        visited = {}
        until fringe.empty?
          node = fringe.shift
          visited[node.first] = true
          if operators.assoc(node.first)
            found = false
            node[2].each {|pre|
              if pre.include?(f) and not precond_pos.assoc(pre.first)
                precond_pos << pre
                new_free.concat(pre.drop(1).select {|i| not ground_var.include?(i) and not free.include?(i)})
                found = true
              end
            }
            break if found
          elsif node.first.start_with?(DEPENDENCY_PREFIX)
            node[node.size-1][4].reverse_each {|i| fringe.unshift(operators.assoc(i.first) || methods.assoc(i.first)) unless visited.include?(i.first)}
          elsif node.first.start_with?(SWAP_PREFIX)
            node[3][4].reverse_each {|i| fringe.unshift(operators.assoc(i.first) || methods.assoc(i.first)) unless visited.include?(i.first)}
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
    operator[2].each {|prec| precond_pos << prec if not predicates[prec.first] and variables.any? {|i| prec.include?(i)}}
    operator[3].each {|prec| precond_not << prec if not predicates[prec.first] and variables.any? {|i| prec.include?(i)}}
  end
end