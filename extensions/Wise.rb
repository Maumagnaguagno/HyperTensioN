module Wise
  extend self

  #-----------------------------------------------
  # Apply
  #-----------------------------------------------

  def apply(operators, methods, predicates, state, tasks, goal_pos, goal_not, debug = true)
    puts 'Wise'.center(50,'-') if debug
    # Initial state
    state.reject! {|pre,k|
      if predicates.include?(pre)
        # Free variable
        raise 'Initial state contains free variable' if k.flatten(1).any? {|t| t.start_with?('?')}
        # Duplicates
        puts "Initial state contains duplicate predicates (#{pre} ...): removed" if k.uniq! and debug
        # Arity check
        puts "Initial state contains (#{pre} ...) with different arity" if k.any? {|i| i.size != k[0].size} and debug
      else
        # Unused predicate
        puts "Initial state contains unused predicates (#{pre} ...): removed" if debug
        true
      end
    }
    # Operators
    noops = []
    operators.reject! {|name,param,precond_pos,precond_not,effect_add,effect_del|
      prefix_variables(opname = "Operator #{name}", param, debug)
      define_variables(opname, param, [precond_pos, precond_not, effect_add, effect_del], debug)
      # Duplicates
      puts "#{opname} contains duplicate parameter: removed" if param.uniq! and debug
      puts "#{opname} contains duplicate positive precondition: removed" if precond_pos.uniq! and debug
      puts "#{opname} contains duplicate negative precondition: removed" if precond_not.uniq! and debug
      puts "#{opname} contains duplicate add effect: removed" if effect_add.uniq! and debug
      puts "#{opname} contains duplicate del effect: removed" if effect_del.uniq! and debug
      # Equality
      precond_pos.each {|pre| raise "#{opname} precondition contains unnecessary (#{pre.join(' ')}), use same variable instead" if pre[0] == '='}
      precond_not.each {|pre| raise "#{opname} precondition contains contradiction (not (#{pre.join(' ')}))" if pre[0] == '=' and pre[1] == pre[2]}
      raise "#{opname} effect contains equality" if effect_add.assoc('=') or effect_del.assoc('=')
      # Precondition contradiction
      (precond_pos & precond_not).each {|pre| raise "#{opname} precondition contains contradiction (#{pre.join(' ')}) and (not (#{pre.join(' ')}))"}
      # Remove null del effect
      (effect_add & effect_del).each {|pre|
        puts "#{opname} contains null del effect (#{pre.join(' ')}): removed" if debug
        effect_del.delete(pre)
      }
      # Effect contained in precondition
      effect_add.reject! {|pre|
        if precond_pos.include?(pre)
          puts "#{opname} add effect (#{pre.join(' ')}) present in precondition: removed" if debug
          true
        end
      }
      effect_del.reject! {|pre|
        if precond_not.include?(pre)
          puts "#{opname} del effect (#{pre.join(' ')}) present in precondition: removed" if debug
          true
        end
      }
      # Unknown previous state of effect, useful for classical instances
      if debug and methods.empty?
        precond_all = precond_pos | precond_not
        (effect_add - precond_all).each {|pre| puts "#{opname} contains side effect (#{pre.join(' ')})"}
        (effect_del - precond_all).each {|pre| puts "#{opname} contains side effect (not (#{pre.join(' ')}))"}
      end
      # Remove noops, invisible operators without preconditions and effects
      if name.start_with?('invisible_') and precond_pos.empty? and precond_not.empty? and effect_add.empty? and effect_del.empty?
        puts "#{opname} is unnecessary: removed" if debug
        noops << name
      end
    }
    # Methods
    methods.each {|name,param,*decompositions|
      prefix_variables(name = "Method #{name}", param, debug)
      # Duplicates
      puts "#{name} contains duplicate parameter: removed" if param.uniq! and debug
      decompositions.each {|label,free,precond_pos,precond_not,subtasks|
        prefix_variables(label = "#{name} #{label}", free, debug)
        define_variables(label, param + free, [precond_pos, precond_not, subtasks], debug)
        puts "#{label} contains duplicate free variable: removed" if free.uniq! and debug
        puts "#{label} contains duplicate positive precondition: removed" if precond_pos.uniq! and debug
        puts "#{label} contains duplicate negative precondition: removed" if precond_not.uniq! and debug
        free.reject! {|v|
          if param.include?(v)
            puts "#{label} free variable shadowing parameter #{v}: removed" if debug
            true
          end
        }
        # Equality
        precond_pos.each {|pre| raise "#{label} precondition contains unnecessary (#{pre.join(' ')}), use same variable instead" if pre[0] == '='}
        precond_not.each {|pre| raise "#{label} precondition contains contradiction (not (#{pre.join(' ')}))" if pre[0] == '=' and pre[1] == pre[2]}
        # Precondition contradiction
        (precond_pos & precond_not).each {|pre| raise "#{label} precondition contains contradiction (#{pre.join(' ')}) and (not (#{pre.join(' ')}))"}
        verify_tasks("#{label} subtask", subtasks, noops, operators, methods, debug)
      }
    }
    # Tasks
    unless tasks.empty?
      ordered = tasks.shift
      verify_tasks('task', tasks, noops, operators, methods, debug)
      tasks.unshift(ordered)
    end
    # Goal
    raise 'Goal contains free variable' if (goal_pos + goal_not).flatten(1).any? {|t| t.start_with?('?')}
    puts "Goal contains duplicate positive condition: removed" if goal_pos.uniq! and debug
    puts "Goal contains duplicate negative condition: removed" if goal_not.uniq! and debug
    (goal_pos & goal_not).each {|pre| raise "Goal contains contradiction (#{pre.join(' ')}) and (not (#{pre.join(' ')}))"}
  end

  #-----------------------------------------------
  # Prefix variables
  #-----------------------------------------------

  def prefix_variables(name, param, debug)
    param.each {|var|
      unless var.start_with?('?')
        puts "#{name} parameter #{var} modified to ?#{var}" if debug
        var.prepend('?')
      end
      raise "#{name} contains invalid #{var}" unless var.match?(/^\?[a-z_][\w-]*$/)
    }
  end

  #-----------------------------------------------
  # Define variables
  #-----------------------------------------------

  def define_variables(name, param, group, debug)
    group.each {|predicates|
      predicates.each {|pre|
        pre.drop(1).each {|term|
          if term.start_with?('?')
            raise "#{name} never declared variable #{term} from (#{pre.join(' ')})" unless param.include?(term)
          elsif param.include?("?#{term}")
            puts "#{name} contains probable variable #{term} from (#{pre.join(' ')}), modifying to ?#{term}" if debug
            term.prepend('?')
          end
        }
      }
    }
  end

  #-----------------------------------------------
  # Verify tasks
  #-----------------------------------------------

  def verify_tasks(name, tasks, noops, operators, methods, debug)
    # Task arity check and noops removal
    tasks.reject! {|task|
      if noops.include?(task[0])
        puts "#{name} #{task[0]}: removed" if debug
        true
      elsif t = operators.assoc(task[0]) || methods.assoc(task[0])
        raise "#{name} #{task[0]} expected #{t[1].size} terms instead of #{task.size.pred}" if t[1].size != task.size.pred
      elsif task[0].start_with?('?')
        puts "#{name} #{task[0]} is variable" if debug
      else raise "#{name} #{task[0]} is unknown"
      end
    }
  end
end