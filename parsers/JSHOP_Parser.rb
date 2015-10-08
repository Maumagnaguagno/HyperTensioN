module JSHOP_Parser
  extend self

  attr_reader :domain_name, :problem_name, :operators, :methods, :predicates, :state, :tasks, :goal_pos, :goal_not

  NOT = 'not'
  NIL = 'nil'

  #-----------------------------------------------
  # Define effects
  #-----------------------------------------------

  def define_effects(name, group, effects)
    raise "Error with #{name} effects" unless group.instance_of?(Array)
    group.each {|pro|
      pro.first == NOT ? raise('Unexpected not in effects') : effects << pro
      @predicates[pro.first.freeze] = true
    }
  end

  #-----------------------------------------------
  # Parse operator
  #-----------------------------------------------

  def parse_operator(op)
    op.shift
    name = op.first.shift
    raise 'Action without name definition' unless name.instance_of?(String)
    name.sub!(/^!!/,'invisible_') or name.sub!(/^!/,'')
    raise "Action #{name} redefined" if @operators.assoc(name)
    raise "Operator #{name} have #{op.size} groups instead of 4" if op.size != 4
    # Header
    @operators << [name, op.shift, pos = [], neg = [], add = [], del = []]
    # Preconditions
    if (group = op.shift) != NIL
      raise "Error with #{name} preconditions" unless group.instance_of?(Array)
      group.each {|pro|
        if pro.first == NOT
          pro.size == 2 ? neg << (pro = pro.last) : raise("Error with #{name} negative precondition group")
        else pos << pro
        end
        @predicates[pro.first.freeze] ||= false
      }
    end
    # Effects
    define_effects(name, group, del) if (group = op.shift) != NIL
    define_effects(name, group, add) if (group = op.shift) != NIL
  end

  #-----------------------------------------------
  # Parse method
  #-----------------------------------------------

  def parse_method(met)
    met.shift
    # Header
    name = (group = met.first).shift
    met.shift
    # Already defined
    method = @methods.assoc(name)
    @methods << method = [name, group] unless method
    until met.empty?
      # Optional label, add index for the unlabeled cases
      method << [met.first.instance_of?(String) ? met.shift : "#{name}_#{method.size - 2}", free_variables = [], pos = [], neg = []]
      # Preconditions
      if (group = met.shift) != NIL
        raise "Error with #{name} preconditions" unless group.instance_of?(Array)
        group.each {|pro|
          if pro.first == NOT
            pro.size == 2 ? neg << (pro = pro.last) : raise("Error with #{name} negative precondition group")
          else pos << pro
          end
          @predicates[pro.first.freeze] ||= false
          free_variables.concat(pro.find_all {|i| i.start_with?('?') and not method[1].include?(i)})
        }
        free_variables.uniq!
      end
      # Subtasks
      if (group = met.shift) != NIL
        raise "Error with #{name} subtasks" unless group.instance_of?(Array)
        group.each {|pro| pro.first.sub!(/^!+/,'')}
        method.last << group
      else method.last << []
      end
    end
  end

  #-----------------------------------------------
  # Parse domain
  #-----------------------------------------------

  def parse_domain(domain_filename)
    if (tokens = PDDL_Parser.scan_tokens(domain_filename)).instance_of?(Array) and tokens.shift == 'defdomain'
      @operators = []
      @methods = []
      raise 'Found group instead of domain name' if tokens.first.instance_of?(Array)
      @domain_name = tokens.shift
      @predicates = {}
      raise 'More than one group to define domain content' if tokens.size != 1
      tokens = tokens.shift
      until tokens.empty?
        case (group = tokens.shift).first
        when ':operator' then parse_operator(group)
        when ':method' then parse_method(group)
        else puts "#{group.first} is not recognized in domain"
        end
      end
    else raise "File #{domain_filename} does not match domain pattern"
    end
  end

  #-----------------------------------------------
  # Parse problem
  #-----------------------------------------------

  def parse_problem(problem_filename)
    if (tokens = PDDL_Parser.scan_tokens(problem_filename)).instance_of?(Array) and tokens.size == 5 and tokens.shift == 'defproblem'
      @problem_name = tokens.shift
      raise 'Different domain specified in problem file' if @domain_name != tokens.shift
      @state = tokens.shift
      @tasks = tokens.shift
      # Tasks may be ordered or unordered
      @tasks.shift unless order = (@tasks.first != ':unordered')
      @tasks.each {|pro| pro.first.sub!(/^!+/,'')}
      @tasks.unshift(order)
      @goal_pos = []
      @goal_not = []
    else raise "File #{problem_filename} does not match problem pattern"
    end
  end
end