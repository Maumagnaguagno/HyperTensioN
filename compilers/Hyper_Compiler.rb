module Hyper_Compiler
  extend self

  TEMPLATE_DOMAIN = "# Generated by Hype
require '../../Hypertension'

module <DOMAIN_NAME>
  include Hypertension
  extend self

  #-----------------------------------------------
  # Domain
  #-----------------------------------------------

  @domain = {
    # Operators<OPERATORS>
    # Methods<METHODS>
  }

  #-----------------------------------------------
  # Operators
  #-----------------------------------------------
<DEFINE_OPERATORS>
  #-----------------------------------------------
  # Methods
  #-----------------------------------------------
<DEFINE_METHODS>end"

  TEMPLATE_PROBLEM = "require './<DOMAIN_FILE>'\n\n# Objects\n<OBJECTS>\n\n<DOMAIN_NAME>.problem(\n  # Start\n  {\n<START>\n  },\n  # Tasks\n  [\n<TASKS>  ]\n)"

  #-----------------------------------------------
  # Propositions to Hyper
  #-----------------------------------------------

  def propositions_to_hyper(output, group)
    if group.empty?
      output << "\n      []"
    else
      output << "\n      [\n"
      group.each_with_index {|g,i| output << "        ['#{g.first}', #{g.drop(1).join(', ')}]#{',' if group.size.pred != i}\n"}
      output << '      ]'
    end
  end

  #-----------------------------------------------
  # Subtasks to Hyper
  #-----------------------------------------------

  def subtasks_to_hyper(output, subtasks, indentation)
    if subtasks.empty?
      output << "#{indentation}yield []\n"
    else
      output << "#{indentation}yield [\n"
      subtasks.each_with_index {|t,i| output << "#{indentation}  ['#{t.first}'#{t.drop(1).map {|i| ", #{i}"}.join}]#{',' if subtasks.size.pred != i}\n"}
      output << "#{indentation}]\n"
    end
  end

  #-----------------------------------------------
  # Method to Hyper
  #-----------------------------------------------

  def method_to_hyper(test, output, method)
    method[1].each {|free| output << "    #{free} = ''\n"}
    output << "    #{test}("
    method[2..3].each_with_index {|group,gi|
      output << "\n      # " << (gi.zero? ? 'True' : 'False') << " preconditions"
      propositions_to_hyper(output, group)
      output << ',' if gi != 1
    }
    method[1].each {|free| output << ", #{free}"}
    output << "\n    )#{' {' unless method[1].empty?}\n"
    subtasks_to_hyper(output, method[4], '      ')
    output << (method[1].empty? ? "    end\n" : "    }\n")
  end

  #-----------------------------------------------
  # Operators to Hyper
  #-----------------------------------------------

  def operators_to_hyper(decompose, output, operators, methods)
    operators.each_with_index {|op,i|
      decompose << "\n    '#{op.first}' => true#{',' if operators.size.pred != i or not methods.empty?}"
      output << "\n  def #{op.first}"
      output << "(#{op[1].join(', ')})" unless op[1].empty?
      output << "\n    apply_operator("
      op[2..5].each_with_index {|group,gi|
        output << "\n      # " << ['True preconditions', 'False preconditions', 'Add effects', 'Del effects'][gi]
        propositions_to_hyper(output, group)
        output << ',' if gi != 3
      }
      output << "\n    )\n  end\n"
    }
  end

  #-----------------------------------------------
  # Methods to Hyper
  #-----------------------------------------------

  def methods_to_hyper(decompose, output, methods)
    methods.each_with_index {|met,mi|
      decompose << "\n    '#{met.first}' => [\n"
      met.drop(2).each_with_index {|met_case,i|
        decompose << "      '#{met_case.first}'#{',' if met.size - 3 != i}\n"
        output << "\n  def #{met_case.first}"
        output << "(#{met[1].join(', ')})" unless met[1].empty?
        output << "\n"
        # No Preconditions
        if met_case[2].empty? and met_case[3].empty?
          subtasks_to_hyper(output, met_case[4], '    ')
        # Grounded
        elsif met_case[1].empty?
          method_to_hyper('if applicable?', output, met_case)
        # Lifted
        else
          method_to_hyper('generate', output, met_case)
        end
        output << "  end\n"
      }
      decompose << "    ]#{',' if methods.size.pred != mi}"
    }
  end

  #-----------------------------------------------
  # Compile domain
  #-----------------------------------------------

  def compile_domain(domain_name, operators, methods, predicates, state, tasks)
    # Operators
    domain_operators = ''
    define_operators = ''
    operators_to_hyper(domain_operators, define_operators, operators, methods)
    # Methods
    domain_methods = ''
    define_methods = ''
    methods_to_hyper(domain_methods, define_methods, methods)
    # Domain
    domain_str = TEMPLATE_DOMAIN.dup
    domain_str.sub!('<DOMAIN_NAME>', domain_name.capitalize)
    domain_str.sub!('<OPERATORS>', domain_operators)
    domain_str.sub!('<METHODS>', domain_methods)
    domain_str.sub!('<DEFINE_OPERATORS>', define_operators)
    domain_str.sub!('<DEFINE_METHODS>', define_methods)
    domain_str
  end

  #-----------------------------------------------
  # Compile Problem
  #-----------------------------------------------

  def compile_problem(domain_name, operators, methods, predicates, state, tasks, domain_filename)
    # Start
    start = ''
    objects = []
    start_hash = {}
    predicates.each_key {|i| start_hash[i] = []}
    state.each {|i| start_hash[i.first] << i.drop(1)}
    start_hash.each_with_index {|(k,v),i|
      if v.empty?
        start << "    '#{k}' => []"
      else
        start << "    '#{k}' => [\n"
        v.each_with_index {|obj,j|
          start << "      [#{obj.join(', ')}]#{',' if v.size.pred != j}\n"
          objects.push(*obj)
        }
        start << '    ]'
      end
      start << ",\n" if start_hash.size.pred != i
    }
    # Tasks
    tasks_str = ''
    tasks.each_with_index {|t,i| tasks_str << "    ['#{t.first}', #{t.drop(1).join(', ')}]#{',' if tasks.size.pred != i}\n"}
    objects.uniq!
    # Problem
    problem_str = TEMPLATE_PROBLEM.dup
    problem_str.sub!('<DOMAIN_FILE>', domain_filename)
    problem_str.sub!('<DOMAIN_NAME>', domain_name.capitalize)
    problem_str.sub!('<START>', start)
    problem_str.sub!('<TASKS>', tasks_str)
    problem_str.sub!('<OBJECTS>', objects.map! {|i| "#{i} = '#{i}'"}.join("\n"))
    problem_str
  end
end