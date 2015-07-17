module JSHOP_Parser
  extend self

  attr_reader :domain_name, :problem_name, :problem_domain, :operators, :methods, :predicates, :state, :tasks, :goal_pos, :goal_not

  #-----------------------------------------------
  # Define effects
  #-----------------------------------------------

  def define_effects(name, type, group, effects)
    raise "Error with #{name} #{type} effects" unless group.instance_of?(Array)
    group.each {|pro|
      raise "Error with negated #{name} #{type} effects" if pro.first == 'not'
      effects << pro
      @predicates[pro.first] = true
    }
  end

  #-----------------------------------------------
  # Parse operator
  #-----------------------------------------------

  def parse_operator(op)
    op.shift
    name = op.first.shift
    raise 'Action without name definition' unless name.instance_of?(String)
    name.sub!(/^!+/,'')
    raise "Action #{name} redefined" if @operators.assoc(name)
    raise "Operator #{name} have #{op.size} groups instead of 4" if op.size != 4
    # Header
    @operators << [name, op.shift, pos = [], neg = [], add = [], del = []]
    # Preconditions
    group = op.shift
    if group != 'nil'
      raise "Error with #{name} preconditions" unless group.instance_of?(Array)
      group.each {|pro|
        if pro.first == 'not'
          raise "Error with #{name} negative precondition group" if pro.size != 2
          pro = pro.last
          neg << pro
        else pos << pro
        end
        @predicates[pro.first] = false unless @predicates.include?(pro.first)
      }
    end
    # Effects
    group = op.shift
    define_effects(name, 'del', group, del) if group != 'nil'
    group = op.shift
    define_effects(name, 'add', group, add) if group != 'nil'
  end

  #-----------------------------------------------
  # Parse method
  #-----------------------------------------------

  def parse_method(met)
    met.shift
    # Header
    group = met.first
    name = group.shift
    # Already defined
    method = @methods.find {|m| m.first == name}
    @methods << method = [name, group] unless method
    met.shift
    until met.empty?
      # Optional label, add index for the unlabeled cases
      decompose = [met.first.instance_of?(String) ? met.shift : "#{name}_#{method.size - 2}", free_variables = [], pos = [], neg = []]
      # Preconditions
      group = met.shift
      if group != 'nil'
        raise "Error with #{name} preconditions" unless group.instance_of?(Array)
        group.each {|pro|
          if pro.first == 'not'
            raise "Error with #{name} negative precondition group" if pro.size != 2
            pro = pro.last
            neg << pro
          else pos << pro
          end
          @predicates[pro.first] = false unless @predicates.include?(pro.first)
          free_variables.push(*pro.find_all {|i| i =~ /^\?/ and not method[1].include?(i)})
        }
        free_variables.uniq!
      end
      # Subtasks
      group = met.shift
      if group != 'nil'
        raise "Error with #{name} subtasks" unless group.instance_of?(Array)
        group.each {|pro| pro.first.sub!(/^!+/,'')}
        decompose << group
      else decompose << []
      end
      method << decompose
    end
  end

  #-----------------------------------------------
  # Parse domain
  #-----------------------------------------------

  def parse_domain(domain_filename)
    description = IO.read(domain_filename)
    description.gsub!(/;.*$|\n/,'')
    description.downcase!
    tokens = Hype.scan_tokens(description)
    if tokens.instance_of?(Array) and tokens.shift == 'defdomain'
      @operators = []
      @methods = []
      raise 'Found group instead of domain name' if tokens.first.instance_of?(Array)
      @domain_name = tokens.shift
      @predicates = {}
      raise 'More than one group to define domain content' if tokens.size != 1
      tokens = tokens.shift
      until tokens.empty?
        group = tokens.shift
        case group.first
        when ':operator' then parse_operator(group)
        when ':method' then parse_method(group)
        else puts "#{group.first} is not recognized"
        end
      end
    else raise "File #{domain_filename} does not match domain pattern"
    end
  end

  #-----------------------------------------------
  # Parse problem
  #-----------------------------------------------

  def parse_problem(problem_filename)
    description = IO.read(problem_filename)
    description.gsub!(/;.*$|\n/,'')
    description.downcase!
    tokens = Hype.scan_tokens(description)
    if tokens.instance_of?(Array) and tokens.size == 5 and tokens.shift == 'defproblem'
      @problem_name = tokens.shift
      @problem_domain = tokens.shift
      @state = tokens.shift
      @tasks = tokens.shift
      # Tasks may be ordered or unordered
      order = (@tasks.first != ':unordered')
      @tasks.shift unless order
      @tasks.each {|pro| pro.first.sub!(/^!+/,'')}
      @tasks.unshift(order)
      @goal_pos = []
      @goal_not = []
    else raise "File #{problem_filename} does not match problem pattern"
    end
  end
end