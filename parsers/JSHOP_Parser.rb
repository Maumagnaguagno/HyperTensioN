module JSHOP_Parser
  extend self

  OPERATOR_NAME = 0
  OPERATOR_PREC = 1
  OPERATOR_DEL_EFF = 2
  OPERATOR_ADD_EFF = 3

  METHOD_NAME = 0
  METHOD_PREC  = 1
  METHOD_SUBTAKS = 2

  attr_reader :domain_name, :problem_name, :problem_domain, :operators, :methods, :predicates, :state, :tasks, :goal

  #-----------------------------------------------
  # Scan groups
  #-----------------------------------------------

  def scan_groups(str)
    group = ''
    count_paren = 0
    str.each_char {|c|
      case c
      when '('
        if count_paren.zero? and not group.empty?
          yield group
          group = ''
        end
        count_paren += 1
        group << c
      when ')'
        count_paren -= 1
        group << c
        if count_paren.zero?
          yield group
          group = ''
        elsif count_paren < 0
          raise "Unmatched parentheses for #{str}"
        end
      else
        if count_paren.zero?
          if c =~ /\w/
            group << c
          elsif not group.empty?
            yield group
            group = ''
          end
        else group << c
        end
      end
    }
  end

  #-----------------------------------------------
  # Parse operator
  #-----------------------------------------------

  def parse_operator(op)
    operator = Array.new(6)
    counter = OPERATOR_NAME
    scan_groups(op) {|value|
      case counter
      when OPERATOR_NAME
        value.scan(/^\(\s*(.+?)\s*\)$/) {|i|
          i = i.first
          i.gsub!(/[?!]/,'')
          i = i.split
          operator[0] = i.shift
          operator[1] = i
        }
      when OPERATOR_PREC
        operator[2] = pos = []
        operator[3] = neg = []
        value.scan(/^\(\s*(.+?)\s*\)$/) {|i|
          i = i.first
          i.gsub!('?','')
          i.scan(/\(\s*(.+?)\s*\)/) {|j|
            if j.first =~ /^not\s*\(\s*(.+)\s*$/
              proposition = $1.split
              neg << proposition
            else
              proposition = j.first.split
              pos << proposition
            end
            @predicates[proposition.first] = true if @predicates[proposition.first].nil?
          }
        }
      when OPERATOR_DEL_EFF
        operator[5] = del = []
        value.scan(/^\(\s*(.+?)\s*\)$/) {|i|
          i = i.first
          i.gsub!('?','')
          i.scan(/\(\s*(.+?)\s*\)/) {|j|
            proposition = j.first.split
            del << proposition
            @predicates[proposition.first] = false
          }
        }
      when OPERATOR_ADD_EFF
        operator[4] = add = []
        value.scan(/^\(\s*(.+?)\s*\)$/) {|i|
          i = i.first
          i.gsub!('?','')
          i.scan(/\(\s*(.+?)\s*\)/) {|j|
            proposition = j.first.split
            add << proposition
            @predicates[proposition.first] = false
          }
        }
        @operators << operator
      else raise "Unknow operator group"
      end
      counter += 1
    }
    raise 'Missing operator groups' if counter != OPERATOR_ADD_EFF.succ
  end

  #-----------------------------------------------
  # Parse method
  #-----------------------------------------------

  def parse_method(met)
    method = []
    counter = METHOD_NAME
    label = true
    complete = false
    decompose = nil
    scan_groups(met) {|value|
      case counter
      when METHOD_NAME
        value.scan(/^\(\s*(.+?)\s*\)$/) {|i|
          i = i.first
          i.gsub!(/[?!]/,'')
          i = i.split
          method << i.shift << i
        }
        # Already defined
        met = @methods.find {|m| m.first == method.first}
        if met
          method = met
        else
          @methods << method
        end
        counter = METHOD_PREC
      when METHOD_PREC
        complete = false
        # Optional label may appear
        if label
          label = false
          if value =~ /\w+/
            decompose = [value]
            next
          else
            # Add numbers as labels for the unlabeled cases
            decompose = ["unlabeled_#{method.size - 2}"]
          end
        end
        decompose << (free_variables = []) << (pos = []) << (neg = [])
        value.scan(/^\(\s*(.+?)\s*\)$/) {|i|
          i = i.first
          i.scan(/\(\s*(.+?)\s*\)/) {|j|
            if j.first =~ /^not\s*\(\s*(.+)\s*$/
              proposition = $1.split
              neg << proposition
            else
              proposition = j.first.split
              pos << proposition
            end
            @predicates[proposition.first] = true if @predicates[proposition.first].nil?
            free_variables.push(*proposition.find_all {|i| i.sub!(/^\?/,'') and not method[1].include?(i)})
          }
        }
        free_variables.uniq!
        counter = METHOD_SUBTAKS
      when METHOD_SUBTAKS
        complete = true
        if value != 'nil'
          subtasks = []
          value.gsub!(/[?!]/,'')
          value.scan(/^\(\s*(.+)\s*\)$/)
          $1.scan(/\(\s*(.+?)\s*\)/) {|tasks| subtasks << tasks.first.split}
          decompose << subtasks
        else decompose << []
        end
        method << decompose
        label = true
        counter = METHOD_PREC
      end
    }
  end

  #-----------------------------------------------
  # Parse domain
  #-----------------------------------------------

  def parse_domain(domain_filename)
    description = IO.read(domain_filename)
    description.gsub!(/;.*$|\n/,'')
    if description =~ /^\s*\(\s*defdomain\s+(\w+)\s*\(\s*(.*)\s*\)\s*\)\s*$/
      @operators = []
      @methods = []
      @domain_name = $1
      @predicates = {}
      scan_groups($2) {|group|
        if group =~ /^\s*\(\s*:(operator|method)\s*(.*)\s*\)\s*$/
          case $1
          when 'operator'
            parse_operator($2)
          when 'method'
            parse_method($2)
          end
        else puts "#{group} is not recognized"
        end
      }
    else raise "File #{domain_filename} does not match domain pattern"
    end
  end

  #-----------------------------------------------
  # Parse problem
  #-----------------------------------------------

  def parse_problem(problem_filename)
    description = IO.read(problem_filename)
    description.gsub!(/;.*$|\n/,'')
    if description =~ /^\s*\(\s*defproblem\s+(\w+)\s+(\w+)\s+\(\s*(.+)\s*\)\s*\)\s*$/
      @problem_name = $1
      @problem_domain = $2
      if $3 =~ /(.*)\s*\)\s*\(\s*(.*)/
        state = $1
        tasks = $2
        @state = []
        @tasks = []
        state.scan(/\(\s*(.+?)\s*\)/) {|values|
          proposition = values.first.split
          @predicates[proposition.first] = nil unless @predicates.include?(proposition.first)
          @state << proposition
        }
        tasks.scan(/\(\s*(.+?)\s*\)/) {|values| @tasks << values.first.split}
      else raise 'Problem does not define two groups'
      end
    else raise "File #{problem_filename} does not match problem pattern"
    end
  end
end