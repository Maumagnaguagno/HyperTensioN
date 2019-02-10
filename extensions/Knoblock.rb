# Based on Automatically Generating Abstractions for Planning
# https://www.isi.edu/integration/papers/knoblock94-aij.pdf
require 'tsort'

module Knoblock
  include TSort
  extend self

  #-----------------------------------------------
  # Apply
  #-----------------------------------------------

  def apply(operators, methods, predicates, state, tasks, goal_pos, goal_not)
    create_hierarchy(operators, map(goal_pos, goal_not))
  end

  #-----------------------------------------------
  # Create hierarchy
  #-----------------------------------------------

  def create_hierarchy(operators, predicates, goals = nil, verbose = false)
    @graph = Hash.new {|h,k| h[k] = []}
    if goals then find_problem_dependent_constraints(operators, predicates, goals)
    else find_problem_independent_constraints(operators, predicates)
    end
    puts 'Dependency graph', dot if verbose
    reduce_graph
    puts 'Partial order graph', dot if verbose
    total_order = tsort
    puts 'Total order', total_order.map {|i| "  #{i}"} if verbose
    total_order
  end

  def tsort_each_node(&block)
    @graph.each_key(&block)
  end

  def tsort_each_child(node, &block)
    @graph.fetch(node, []).each(&block)
  end

  #-----------------------------------------------
  # Map
  #-----------------------------------------------

  def map(positive, negative, predicates)
    positive.select {|pre| predicates[pre.first]}.map! {|pre| [true, pre]} + negative.select {|pre| predicates[pre.first]}.map! {|pre| [false, pre]}
  end

  #-----------------------------------------------
  # Find problem independent constraints
  #-----------------------------------------------

  def find_problem_independent_constraints(operators, predicates)
    operators.each {|op|
      preconditions = map(op[2], op[3], predicates)
      effects = map(op[4], op[5], predicates)
      effects.each {|literal|
        @graph[literal].concat(preconditions).concat(effects).delete(literal)
      }
    }
    @graph.each_value {|v| v.uniq!}
  end

  #-----------------------------------------------
  # Find problem dependent constraints
  #-----------------------------------------------

  def find_problem_dependent_constraints(operators, predicates, goals)
    goals.each {|literal|
      unless @graph.include?(literal)
        operators.each {|op|
          effects = map(op[4], op[5], predicates)
          if effects.include?(literal)
            preconditions = map(op[2], op[3], predicates)
            @graph[literal].concat(preconditions).concat(effects).delete(literal)
            find_problem_dependent_constraints(operators, predicates, preconditions)
          end
        }
      end
    }
    @graph.each_value {|v| v.uniq!}
  end

  #-----------------------------------------------
  # Reduce graph
  #-----------------------------------------------

  def reduce_graph
    strongly_connected_components.each {|component|
      if component.size > 1
        g = @graph[component]
        component.each {|c|
          g.concat(@graph[c] - component).delete(component)
          @graph.each_value {|v| v.map! {|i| i == c ? component : i}}.delete(c)
        }
      end
    }
    @graph.each_value {|v| v.uniq!}
  end

  #-----------------------------------------------
  # DOT
  #-----------------------------------------------

  def dot
    graph_str = "digraph G {\n"
    @graph.each {|k,v|
      graph_str << "  \"#{dot_str(k)}\" -> {#{"\"#{v.map {|i| dot_str(i)}.join('" "')}\"" unless v.empty?}}\n"
    }
    graph_str << '}'
  end

  def dot_str(i)
    i.first.instance_of?(Array) ? i.map {|j| dot_str(j)}.join(' ') : i.first ? i.last.join(' ') : "not #{i.last.join(' ')}"
  end
end

if $0 == __FILE__
  require_relative 'HyperTensioN/parsers/PDDL_Parser'
  begin
    PDDL_Parser.parse_domain(ARGV.first)
    Knoblock.create_hierarchy(PDDL_Parser.operators, PDDL_Parser.predicates)
  rescue
    puts $!, $@
  end
end