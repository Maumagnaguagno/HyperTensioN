# Based on Automatically Generating Abstractions for Planning
# https://usc-isi-i2.github.io/papers/knoblock94-aij.pdf
require 'tsort'

module Knoblock
  extend self

  #-----------------------------------------------
  # Create hierarchy
  #-----------------------------------------------

  def create_hierarchy(operators, predicates, goals = nil, verbose = false)
    graph = Hash.new {|h,k| h[k] = []}
    if goals then find_problem_dependent_constraints(operators, predicates, goals, graph)
    else find_problem_independent_constraints(operators, predicates, graph)
    end
    puts 'Dependency graph', dot(graph) if verbose
    reduce_graph(graph, each_node = lambda {|&b| graph.each_key(&b)}, each_child = lambda {|n,&b| graph.fetch(n, []).each(&b)})
    puts 'Partial order graph', dot(graph) if verbose
    total_order = TSort.tsort(each_node, each_child)
    puts 'Total order', total_order.map {|i| "  #{i}"} if verbose
    total_order
  end

  #-----------------------------------------------
  # Map
  #-----------------------------------------------

  def map(positive, negative, predicates)
    m = []
    positive.each {|pre| m << [true, pre] if predicates[pre[0]]}
    negative.each {|pre| m << [false, pre] if predicates[pre[0]]}
    m
  end

  #-----------------------------------------------
  # Find problem independent constraints
  #-----------------------------------------------

  def find_problem_independent_constraints(operators, predicates, graph)
    operators.each {|op|
      preconditions_effects = map(op[2], op[3], predicates).concat(effects = map(op[4], op[5], predicates))
      effects.each {|literal| graph[literal].concat(preconditions_effects).delete(literal)}
    }
    graph.each_value(&:uniq!)
  end

  #-----------------------------------------------
  # Find problem dependent constraints
  #-----------------------------------------------

  def find_problem_dependent_constraints(operators, predicates, goals, graph)
    goals.each {|literal|
      unless graph.include?(literal)
        operators.each {|op|
          if (effects = map(op[4], op[5], predicates)).include?(literal)
            graph[literal].concat(preconditions = map(op[2], op[3], predicates), effects).delete(literal)
            find_problem_dependent_constraints(operators, predicates, preconditions, graph)
          end
        }
      end
    }
    graph.each_value(&:uniq!)
  end

  #-----------------------------------------------
  # Reduce graph
  #-----------------------------------------------

  def reduce_graph(graph, each_node, each_child)
    TSort.strongly_connected_components(each_node, each_child).each {|component|
      if component.size > 1
        g = graph[component]
        component.each {|c|
          g.concat(graph.delete(c) - component).delete(component)
          graph.each_value {|v| v.map! {|i| i == c ? component : i}}
        }
      end
    }
    graph.each_value(&:uniq!)
  end

  #-----------------------------------------------
  # DOT
  #-----------------------------------------------

  def dot(graph)
    graph_str = "digraph G {\n"
    graph.each {|k,v| graph_str << "  \"#{dot_str(k)}\" -> {\"#{v.map {|i| dot_str(i)}.join('" "')}\"}\n" unless v.empty?}
    graph_str << '}'
  end

  def dot_str(i)
    i[0].instance_of?(Array) ? i.map {|j| dot_str(j)}.join(' &and; ') : i[0] ? i[1].join(' ') : "not #{i[1].join(' ')}"
  end
end

#-----------------------------------------------
# Main
#-----------------------------------------------
if $0 == __FILE__
  require_relative '../parsers/PDDL_Parser'
  begin
    PDDL_Parser.parse_domain(ARGV[0])
    if ARGV[1]
      PDDL_Parser.parse_problem(ARGV[1])
      goals = Knoblock.map(PDDL_Parser.goal_pos, PDDL_Parser.goal_not, PDDL_Parser.predicates)
    end
    Knoblock.create_hierarchy(PDDL_Parser.operators, PDDL_Parser.predicates, goals, true)
  rescue
    puts $!, $@
    exit(2)
  end
end