module JSHOP_Parser
  extend self

  attr_reader :domain_name, :problem_name, :problem_domain, :operators, :methods, :predicates, :state, :tasks, :goal_pos, :goal_not

  #-----------------------------------------------
  # Parse operator
  #-----------------------------------------------

  def parse_operator(op)
    op.shift
    raise "Operator #{op.first.first} have #{op.size} groups instead of 4" if op.size != 4
    # Header
    op.shift.each {|i| i.sub!(/^!+/,'')}
    @operators << [name = group.shift, group, pos = [], neg = [], add = [], del = []]
    # Preconditions
    group = op.shift
    if group != 'nil'
      raise "Error with #{name} preconditions" unless group.instance_of?(Array)
      group.each {|pro|
        if pro.first == 'not'
          raise "Error with #{name} negative precondition group" if pro.size != 2
          proposition = pro.last
          neg << proposition
        else
          proposition = pro
          pos << proposition
        end
        @predicates[proposition.first] = true if @predicates[proposition.first].nil?
      }
    end
    # Effects
    group = op.shift
    if group != 'nil'
      raise "Error with #{name} del effects" unless group.instance_of?(Array)
      group.each {|proposition|
        raise "Error with #{name} del effects" if proposition.first == 'not'
        del << proposition
        @predicates[proposition.first] = false
      }
    end
    group = op.shift
    if group != 'nil'
      raise "Error with #{name} add effects" unless group.instance_of?(Array)
      group.each {|proposition|
        raise "Error with #{name} add effects" if proposition.first == 'not'
        add << proposition
        @predicates[proposition.first] = false
      }
    end
  end

  #-----------------------------------------------
  # Parse method
  #-----------------------------------------------

  def parse_method(met)
    met.shift
    # Header
    group = met.first
    group.each {|i| i.sub!(/^!+/,'')}
    name = group.shift
    # Already defined
    method = @methods.find {|m| m.first == name}
    @methods << method = [name, group] unless method
    met.shift
    until met.empty?
      # Optional label
      if met.first.instance_of?(String)
        decompose = [met.shift, free_variables = [], pos = [], neg = []]
      # Add numbers as labels for the unlabeled cases
      else decompose = ["unlabeled_#{method.size - 2}"]
      end
      # Preconditions
      group = met.shift
      if group != 'nil'
        raise "Error with #{name} preconditions" unless group.instance_of?(Array)
        group.each {|pro|
          if pro.first == 'not'
            raise "Error with #{name} negative precondition group" if pro.size != 2
            proposition = pro.last
            neg << proposition
          else
            proposition = pro
            pos << proposition
          end
          free_variables.push(*proposition.find_all {|i| i =~ /^\?/ and not method[1].include?(i)})
          @predicates[proposition.first] = true if @predicates[proposition.first].nil?
        }
        free_variables.uniq!
      end
      # Subtasks
      group = met.shift
      if group != 'nil'
        raise "Error with #{name} subtasks" unless group.instance_of?(Array)
        group.each {|pro| pro.each {|i| i.sub!(/^!+/,'')}}
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
    tokens = Hype.scan_tokens(description)
    if tokens.instance_of?(Array) and tokens.size == 5 and tokens.shift == 'defproblem'
      @problem_name = tokens.shift
      @problem_domain = tokens.shift
      @state = tokens.shift
      @state.each {|proposition| @predicates[proposition.first] = nil unless @predicates.include?(proposition.first)}
      @tasks = tokens.shift
      @goal_pos = []
      @goal_not = []
    else raise "File #{problem_filename} does not match problem pattern"
    end
  end
end