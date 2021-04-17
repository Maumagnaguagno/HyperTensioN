module Cyber_Compiler
  extend self

  #-----------------------------------------------
  # Term
  #-----------------------------------------------

  def term(term)
    term.start_with?('?') ? term.tr('?','_') : term.upcase
  end

  #-----------------------------------------------
  # Terms to Hyper
  #-----------------------------------------------

  def terms_to_hyper(terms)
    terms.size == 1 ? term(terms[0]) : "std::make_tuple(#{terms.map {|t| term(t)}.join(', ')})"
  end

  #-----------------------------------------------
  # Applicable
  #-----------------------------------------------

  def applicable(pre, terms, predicates, arity)
    arity[pre] ||= terms.size
    if terms.empty? then "state->#{pre}"
    else predicates[pre] ? "applicable(#{pre}, #{terms_to_hyper(terms)})" : "applicable_const(#{pre}, #{terms_to_hyper(terms)})"
    end
  end

  #-----------------------------------------------
  # Apply
  #-----------------------------------------------

  def apply(modifier, effects, define_operators, duplicated, arity)
    effects.each {|pre,*terms|
      if terms.empty? then define_operators << "\n  state->#{pre} = #{modifier == 'insert'};"
      else
        unless duplicated.include?(pre)
          define_operators << "\n  state->#{pre} = new VALUE#{terms.size}(*(state->#{pre}));"
          arity[pre] ||= terms.size
          duplicated[pre] = nil
        end
        define_operators << "\n  state->#{pre}->#{modifier}(#{terms_to_hyper(terms)});"
      end
    }
  end

  #-----------------------------------------------
  # Tasks to Hyper
  #-----------------------------------------------

  def tasks_to_hyper(output, tasks, indentation, next_task = 'next')
    tasks.each_with_index {|s,i|
      output << "#{indentation}subtask#{i}->value = #{s.first.upcase};#{indentation}subtask#{i}->parameters[0] = #{s.size - 1};"
      1.upto(s.size - 1) {|j| output << "#{indentation}subtask#{i}->parameters[#{j}] = #{term(s[j])};"}
      output << "#{indentation}subtask#{i}->next = #{i != tasks.size - 1 ? "subtask#{i + 1}" : next_task};"
    }
  end

  #-----------------------------------------------
  # Compile domain
  #-----------------------------------------------

  def compile_domain(domain_name, problem_name, operators, methods, predicates, state, tasks, goal_pos, goal_not)
    # Operators
    arity = {}
    define_operators = ''
    define_visit = []
    state_visit = -1 if operators.any? {|name,param| param.empty? and name.start_with?('invisible_visit_', 'invisible_mark_')}
    operators.each {|name,param,precond_pos,precond_not,effect_add,effect_del|
      define_operators << "\n\nstatic bool #{name}(const VALUE *parameters, Task *next)\n{"
      param.each_with_index {|v,i| define_operators << "\n  VALUE #{v.tr('?','_')} = parameters[#{i + 1}];"}
      if state_visit
        if name.start_with?('invisible_visit_', 'invisible_mark_')
          define_operators << "\n  return state_visit#{state_visit += 1}.insert(*state).second;\n}"
          next
        elsif name.start_with?('invisible_unvisit_', 'invisible_unmark_')
          define_operators << "\n  return true;\n}"
          next
        end
      elsif name.start_with?('invisible_visit_')
        define_operators << "\n  visit#{param.size}.insert(std::make_tuple(#{param.map.with_index {|_,i| "parameters[#{i + 1}]"}.join(', ')}));"
        define_visit << param.size
      elsif name.start_with?('invisible_unvisit_')
        define_operators << "\n  visit_clear();"
      end
      equality = []
      precond_pos.each {|pre,*terms|
        if pre == '=' then equality << "#{term(terms[0])} != #{term(terms[1])}"
        elsif not predicates[pre] and not state.include?(pre) then define_operators << "\n    return"
        else define_operators << "\n  if(!#{applicable(pre, terms, predicates, arity)}) return false;"
        end
      }
      precond_not.each {|pre,*terms|
        if pre == '=' then equality << "#{term(terms[0])} == #{term(terms[1])}"
        elsif predicates[pre] or state.include?(pre) then define_operators << "\n  if(#{applicable(pre, terms, predicates, arity)}) return false;"
        end
      }
      define_operators << "\n    return if #{equality.join(' || ')}" unless equality.empty?
      unless effect_add.empty? and effect_del.empty?
        define_operators << "\n  new_state();"
        apply('erase', effect_del, define_operators, duplicated = {}, arity)
        apply('insert', effect_add, define_operators, duplicated, arity)
      end
      define_operators << "\n  return true;\n}"
    }
    # Methods
    visit = false
    define_methods = ''
    methods.each {|name,param,*decompositions|
      decomp = []
      param_str = ''
      param.each_with_index {|v,i| param_str << "\n  VALUE #{v.tr('?','_')} = parameters[#{i + 1}];"}
      decompositions.each {|dec|
        define_methods << "\n\nstatic bool #{name}_#{dec[0]}(const VALUE *parameters, Task *next)\n{#{param_str}"
        visit_param = nil
        dec[4].each {|s|
          if s.size > 1 and s.first.start_with?('invisible_visit_')
            visit_param = s.drop(1)
            visit = true
            break
          end
        }
        equality = []
        define_methods_comparison = ''
        f = dec[1]
        precond_pos = dec[2].sort_by {|pre| (pre & param).size * -100 - (pre & f).size}
        precond_pos.reject! {|pre,*terms|
          if (terms & f).empty?
            if pre == '=' then equality << "#{term(terms[0])} != #{term(terms[1])}"
            elsif not predicates[pre] and not state.include?(pre) then define_methods << "\n  return false;"
            else define_methods_comparison << "\n  if(!#{applicable(pre, terms, predicates, arity)}) return false;"
            end
          end
        }
        precond_not = dec[3].reject {|pre,*terms|
          if terms.empty? and pre.start_with?('visited_') then predicates[pre] = nil
          elsif not predicates[pre] and not state.include?(pre) then true
          elsif (terms & f).empty?
            if pre == '=' then equality << "#{term(terms[0])} == #{term(terms[1])}"
            else define_methods_comparison << "\n  if(#{applicable(pre, terms, predicates, arity)}) return false;"
            end
          end
        }
        define_methods << "\n  if(#{equality.join(' || ')}) return false;" unless equality.empty?
        define_methods << define_methods_comparison
        if visit_param and (visit_param & f).empty?
          define_methods << "\n  if(applicable_const(visit#{visit_param.size}, #{terms_to_hyper(visit_param)})) return false;"
          visit_param = nil
        end
        unless dec[4].empty?
          malloc = []
          dec[4].each_with_index {|s,i|
            define_methods << "\n  Task *subtask#{i} = (Task *) malloc(task_size(#{s.size - 1}));"
            malloc << "subtask#{i}"
          }
          define_methods << "\n  malloc_test(#{malloc.join(' && ')});"
        end
        close_method_str = ''
        indentation = "\n  "
        counter = -1
        # Lifted
        predicate_loops = []
        unless f.empty?
          ground = param.dup
          until precond_pos.empty?
            pre, *terms = precond_pos.shift
            equality.clear
            define_methods_comparison.clear
            new_grounds = false
            terms2 = terms.map {|j|
              if not j.start_with?('?')
                equality << "_#{j}_ground != #{j.upcase}"
                "_#{j}_ground"
              elsif ground.include?(j)
                equality << "#{j}_ground != #{j}".tr!('?','_')
                term("#{j}_ground")
              else
                new_grounds = true
                ground << f.delete(j)
                term(j)
              end
            }
            if new_grounds
              if predicates[pre]
                unless predicate_loops.include?(pre)
                  predicate_loops << pre
                  define_methods << "#{indentation}const auto #{pre} = state->#{pre};"
                end
                define_methods << "#{indentation}for(VALUE#{terms.size}::iterator it#{counter += 1} = #{pre}->begin(); it#{counter} != #{pre}->end(); ++it#{counter})#{indentation}{"
              else
                define_methods << "#{indentation}return false;" unless state.include?(pre)
                pre2 = pre == '=' ? 'equal' : pre
                define_methods << "#{indentation}for(VALUE#{terms.size}::iterator it#{counter += 1} = #{pre2}.begin(); it#{counter} != #{pre2}.end(); ++it#{counter})#{indentation}{"
              end
              # close_method_str.prepend('}') and no indentation change for compact output
              close_method_str.prepend("#{indentation}}")
              indentation << '  '
              if terms2.size == 1 then define_methods << "#{indentation}VALUE #{terms2.first} = *it#{counter};"
              else terms2.each_with_index {|term,i| define_methods << "#{indentation}VALUE #{term} = std::get<#{i}>(*it#{counter});"}
              end
            elsif pre == '=' then equality << "#{terms2[0]} != #{terms2[1]}"
            elsif not predicates[pre] and not state.include?(pre) then define_methods << "#{indentation}return"
            else define_methods_comparison << "#{indentation}if(!#{applicable(pre, terms, predicates, arity)}) continue;"
            end
            precond_pos.reject! {|pre,*terms|
              if (terms & f).empty?
                if pre == '=' then equality << "#{term(terms[0])} != #{term(terms[1])}"
                elsif not predicates[pre] and not state.include?(pre) then define_methods << "#{indentation}return false;"
                else define_methods_comparison << "#{indentation}if(!#{applicable(pre, terms, predicates, arity)}) continue;"
                end
              end
            }
            precond_not.reject! {|pre,*terms|
              if (terms & f).empty?
                if pre == '=' then equality << "#{term(terms[0])} == #{term(terms[1])}"
                elsif predicates[pre] or state.include?(pre) then define_methods_comparison << "#{indentation}if(#{applicable(pre, terms, predicates, arity)}) continue;"
                end
              end
            }
            define_methods << "#{indentation}if(#{equality.join(' || ')}) continue;" unless equality.empty?
            define_methods << define_methods_comparison
            if visit_param and (visit_param & f).empty?
              define_methods << "#{indentation}if(applicable_const(visit#{visit_param.size}, #{terms_to_hyper(visit_param)})) continue;"
              visit_param = nil
            end
          end
          equality.clear
          define_methods_comparison.clear
          precond_not.each {|pre,*terms|
            if pre == '=' then equality << "#{term(terms[0])} == #{term(terms[1])}"
            elsif predicates[pre] or state.include?(pre) then define_methods_comparison << "#{indentation}if(#{applicable(pre, terms, predicates, arity)}) continue;"
            end
          }
          define_methods << "#{indentation}if(#{equality.join(' || ')}) continue;" unless equality.empty?
          define_methods << define_methods_comparison
        end
        if dec[4].empty? then define_methods << "#{indentation}yield(next);\n  return false;\n}"
        else
          tasks_to_hyper(define_methods, dec[4], indentation)
          define_methods << "#{indentation}yield(subtask0);#{close_method_str}"
          malloc.each {|s| define_methods << "\n  free(#{s});"}
          define_methods << "\n  return false;\n}"
        end
        decomp << "#{name}_#{dec[0]}(parameters, next)"
      }
      define_methods << "\n\nstatic bool #{name}(const VALUE *parameters, Task *next)\n{\n  return #{decomp.join(' || ')};\n}"
    }
    # Definitions
    template = TEMPLATE.dup
    template.sub!('<OPERATORS>', define_operators)
    template.sub!('<METHODS>', define_methods)
    visible = 0
    tokens = operators.map(&:first).sort_by! {|i|
      visible += 1 unless i = i.start_with?('invisible_')
      i ? 1 : 0
    }.concat(methods.map(&:first))
    template.sub!('<INVISIBLE_BASE_INDEX>', visible.to_s)
    template.sub!('<METHODS_BASE_INDEX>', operators.size.to_s)
    template.sub!('<DOMAIN>', tokens.join(",\n  "))
    tokens.concat(predicates.keys)
    # Start
    define_start = ''
    define_state = ''
    define_state_const = ''
    define_delete = []
    comparison = []
    predicates.each {|pre,type|
      k = state[pre]
      if type
        if (a = arity[pre]) == 0
          define_state << "\n  VALUE0 #{pre};"
          define_start << "\n  start.#{pre} = #{k ? true : false}"
        else
          define_state << "\n  VALUE#{a} *#{pre};"
          define_delete << "\n  if(old_state->#{pre} != state->#{pre}) delete state->#{pre}"
          define_start << "\n  start.#{pre} = new VALUE#{a}"
          if k
            define_start << "\n  {\n    #{k.map {|value| terms_to_hyper(value)}.join(",\n    ")}\n  }"
            tokens.concat(k.flatten)
          end
        end
        comparison << pre
        define_start << ';'
      elsif k
        define_state_const << "\nstatic VALUE#{arity[pre] ||= k.first.size} #{pre == '=' ? 'equal' : pre}\n{\n  #{k.map {|value| terms_to_hyper(value)}.join(",\n  ")}\n};"
        tokens.concat(k.flatten)
      end
    }
    template.sub!('<STATE>', define_state)
    define_visit.uniq!
    define_visit.each {|i| define_state_const << "\nstatic VALUE#{i} visit#{i};"}
    if state_visit
      define_state_const << "\n\nstruct state_cmp\n{  inline bool operator ()(const State &a, const State &b)\n  {\n    return (memcmp(&a, &b, sizeof(State)) < 0) || (#{comparison.map {|i| "(&a.#{i} == &b.#{i})"}.join(' && ')});\n  }\n};"
      (state_visit + 1).times {|i| define_state_const << "\nstd::set<State,state_cmp> state_visit#{i};"}
    end
    template.sub!('<STATE_CONST>', define_state_const)
    template.sub!('<CLEAR>', define_visit.map! {|i| "\n  visit#{i}.clear()"}.join('; \\'))
    template.sub!('<DELETE>', define_delete.join('; \\'))
    template.sub!('<START>', define_start)
    tasks.drop(1).each {|_,*terms| tokens.concat(terms)}
    goal_pos.each {|_,*terms| tokens.concat(terms)}
    goal_not.each {|_,*terms| tokens.concat(terms)}
    tokens_str = ''
    tokens.uniq!
    tokens.each_with_index {|t,i| tokens_str << "\n#define #{t == '=' ? 'EQUAL' : t.upcase} #{i}"}
    template.sub!('<TOKEN_MAX_SIZE>', (tokens.max_by(&:size).size + 1).to_s)
    template.sub!('<TOKENS>', tokens_str)
    template.sub!('<STRINGS>', tokens.map! {|i| "\"#{i}\""}.join(",\n  "))
    (arity = arity.values).uniq!
    arity.sort!
    arity.shift while arity.first < 2
    template.sub!('<VALUE_TYPE>', tokens.size <= 256 ? 'unsigned char' : 'unsigned int')
    template.sub!('<VALUES>', arity.map! {|v| "\ntypedef std::set<std::tuple<#{Array.new(v,'VALUE').join(',')}>> VALUE#{v};"}.join)
    # Tasks
    if tasks.empty? then template.sub!('<TASK0>', 'NULL')
    else
      define_tasks = ''
      ordered = tasks.shift
      tasks.each_with_index {|s,i| define_tasks << "\n  Task *subtask#{i} = (Task *) malloc(task_size(#{s.size - 1}));"}
      tasks_to_hyper(define_tasks, tasks, "\n  ", 'NULL')
      tasks.unshift(ordered)
      template.sub!('<TASKS>', define_tasks)
      template.sub!('<TASK0>', 'subtask0')
    end
    template.gsub!(/\b-\b/,'_')
    template
  end

  #-----------------------------------------------
  # Compile problem
  #-----------------------------------------------

  def compile_problem(domain_name, problem_name, operators, methods, predicates, state, tasks, goal_pos, goal_not, domain_filename)
  end

  TEMPLATE =
'#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <set>
#include <tuple>

//#define DEBUG

#define TOKEN_MAX_SIZE <TOKEN_MAX_SIZE>
#define INVISIBLE_BASE_INDEX <INVISIBLE_BASE_INDEX>
#define METHODS_BASE_INDEX <METHODS_BASE_INDEX>
#define DOMAIN_SIZE (sizeof(domain) / sizeof(*domain))
#define task_size(parameters) (sizeof(Task) + sizeof(VALUE) * (parameters))
#define applicable(predicate, value) (state->predicate->find(value) != state->predicate->end())
#define applicable_const(predicate, value) (predicate.find(value) != predicate.end())
#define new_state()                                   \\
  State *new_state = (State *) malloc(sizeof(State)); \\
  malloc_test(new_state);                             \\
  memcpy(new_state, state, sizeof(State));            \\
  state = new_state

#define visit_clear() \\<CLEAR>

#define delete_predicates() \\<DELETE>

#define no_subtasks keep_planning(next)
#define yield(subtasks)            \\
  Plan *plan = planning(subtasks); \\
  if(plan != NULL)                 \\
  {                                \\
    next_plan = plan;              \\
    return true;                   \\
  }

#ifdef DEBUG
#define error(m) puts(m); exit(EXIT_FAILURE)
#else
#define error(m) exit(EXIT_FAILURE)
#endif

#define malloc_test(condition) if(!(condition)) error("Malloc error")

// Tokens<TOKENS>

static char tokens[][TOKEN_MAX_SIZE] = {
  <STRINGS>
};

typedef <VALUE_TYPE> VALUE;
typedef bool VALUE0;
typedef std::set<VALUE> VALUE1;<VALUES>

struct Node
{
  struct Node *next;
  VALUE value;
  VALUE parameters[1];
};

typedef Node Plan;
typedef Node Task;
static Node *next_plan, empty;

struct State
{<STATE>
};
static State *state;
<STATE_CONST>

static Plan* planning(Task *tasks);

//-----------------------------------------------
// Operators
//-----------------------------------------------<OPERATORS>

//-----------------------------------------------
// Methods
//-----------------------------------------------<METHODS>

static bool (*domain[])(const VALUE *, Task *) = {
  <DOMAIN>
};

static void print_task(const VALUE value, const VALUE *parameters)
{
  printf(tokens[value]);
  for(VALUE i = 1; i <= parameters[0]; ++i) printf(" %s", tokens[parameters[i]]);
  puts("");
}

static Plan* planning(Task *tasks)
{
  // Empty tasks
  if(tasks == NULL)
  {
#ifdef DEBUG
    puts("Empty tasks");
#endif
    return &empty;
  }
#ifdef DEBUG
  static unsigned int level = 0;
  if(tasks->value >= DOMAIN_SIZE)
  {
    printf("Domain defines no decomposition for index %u\\n", tasks->value);
    exit(EXIT_FAILURE);
  }
  printf("planning %u: %u %p\\n", level++, tasks->value, tasks->next);
  print_task(tasks->value, tasks->parameters);
#endif
  // Operator
  if(tasks->value < METHODS_BASE_INDEX)
  {
    State *old_state = state;
    if(domain[tasks->value](tasks->parameters, NULL))
    {
      Plan *plan = planning(tasks->next);
      if(plan != NULL)
      {
        if(tasks->value < INVISIBLE_BASE_INDEX)
        {
          tasks->next = plan;
          return tasks;
        }
        return plan;
      }
      if(state != old_state)
      {
        delete_predicates();
        free(state);
      }
    }
    state = old_state;
  }
  // Method
  else if(domain[tasks->value](tasks->parameters, tasks->next))
  {
    return next_plan;
  }
  // Failure
  return NULL;
}

int main(void)
{
  // Start
  State start;<START>
  state = &start;
  // Tasks<TASKS>
  // Planning
  puts("Planning...");
  Plan *result = planning(<TASK0>);
  // Print plan
  if(result != NULL)
  {
    if(result == &empty)
    {
      puts("Empty plan");
    }
    else
    {
      do
      {
        print_task(result->value, result->parameters);
        result = result->next;
      } while(result != &empty);
    }
    return EXIT_SUCCESS;
  }
  puts("Planning failed");
  return EXIT_FAILURE;
}'
end