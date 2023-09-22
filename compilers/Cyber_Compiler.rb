module Cyber_Compiler
  extend self

  #-----------------------------------------------
  # Term
  #-----------------------------------------------

  def term(term)
    term.start_with?('?') ? term.tr('?','_') : "t_#{term}"
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
    if terms.empty? then predicates[pre] ? "state->#{pre}_" : "#{pre}_"
    else
      arity[pre] ||= terms.size
      predicates[pre] ? "applicable(#{pre}_, #{terms_to_hyper(terms)})" : "applicable_const(#{pre}_, #{terms_to_hyper(terms)})"
    end
  end

  #-----------------------------------------------
  # Apply
  #-----------------------------------------------

  def apply(modifier, effects, define_operators, duplicated, arity)
    effects.each {|pre,*terms|
      if (a = arity[pre] ||= terms.size) == 0 then define_operators << "\n  state->#{pre}_ = #{modifier == 'insert'};"
      else
        unless duplicated.include?(pre)
          define_operators << "\n  state->#{pre}_ = new VALUE#{a}(*state->#{pre}_);"
          duplicated[pre] = nil
        end
        define_operators << "\n  state->#{pre}_->#{modifier}(#{terms_to_hyper(terms)});"
      end
    }
  end

  #-----------------------------------------------
  # Tasks to Hyper
  #-----------------------------------------------

  def tasks_to_hyper(output, tasks, indentation, next_task = 'task->next')
    tasks.each_with_index {|s,i|
      output << "#{indentation}subtask#{i}->value = #{term(s.first)};"
      output << "#{indentation}tindex(subtask#{i});" unless s.first.start_with?('invisible_')
      output << "#{indentation}subtask#{i}->parameters[0] = #{s.size - 1};"
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
    # Goal becomes an invisible task
    unless goal_pos.empty? and goal_not.empty?
      tasks << true if tasks.empty?
      tasks << [invisible_goal = 'invisible_goal']
      operators << [invisible_goal, [], goal_pos, goal_not, [], []]
    end
    operators.each {|name,param,precond_pos,precond_not,effect_add,effect_del|
      define_operators << "\n\nstatic bool #{name}_(const Task *task)\n{\n  const VALUE *parameters = task->parameters;"
      param.each_with_index {|v,i| define_operators << "\n  VALUE #{v.tr('?','_')} = parameters[#{i + 1}];"}
      if state_visit
        if name.start_with?('invisible_visit_', 'invisible_mark_')
          define_operators << "\n  return state_visit#{state_visit += 1}.insert(state).second;\n}"
          next
        elsif name.start_with?('invisible_unvisit_', 'invisible_unmark_')
          define_operators << "\n  return true;\n}"
          next
        end
      elsif name.start_with?('invisible_visit_')
        define_operators << "\n  visit#{param.size}.insert(#{terms_to_hyper(param)});"
        define_visit << param.size
      elsif name.start_with?('invisible_unvisit_')
        define_operators << "\n  visit_clear();"
      end
      equality = []
      precond_pos.each {|pre,*terms|
        if pre == '=' then equality << "#{term(terms[0])} != #{term(terms[1])}"
        elsif not predicates[pre] || state.include?(pre) then define_operators << "\n  return false;"
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
    define_methods = ''
    labels = []
    methods.each {|name,param,*decompositions|
      param_str = ''
      param.each_with_index {|v,i| param_str << "\n  VALUE #{v.tr('?','_')} = parameters[#{i + 1}];"}
      decompositions.map! {|dec|
        define_methods << "\n\nstatic bool #{name}_#{dec[0]}_(const Task *task)\n{\n  const VALUE *parameters = task->parameters;#{param_str}"
        equality = []
        define_methods_comparison = ''
        f = dec[1]
        precond_pos = dec[2].sort_by {|pre| (pre & param).size * -100 - (pre & f).size}
        precond_pos.reject! {|pre,*terms|
          if (terms & f).empty?
            if pre == '=' then equality << "#{term(terms[0])} != #{term(terms[1])}"
            elsif not predicates[pre] || state.include?(pre) then define_methods << "\n  return false;"
            else define_methods_comparison << "\n  if(!#{applicable(pre, terms, predicates, arity)}) return false;"
            end
          end
        }
        precond_not = dec[3].reject {|pre,*terms|
          if terms.empty? and pre.start_with?('visited_') then predicates[pre] = nil
          elsif not predicates[pre] || state.include?(pre) then true
          elsif (terms & f).empty?
            if pre == '=' then equality << "#{term(terms[0])} == #{term(terms[1])}"
            else define_methods_comparison << "\n  if(#{applicable(pre, terms, predicates, arity)}) return false;"
            end
          end
        }
        define_methods << "\n  if(#{equality.join(' || ')}) return false;" unless equality.empty?
        define_methods << define_methods_comparison
        visit_param = nil
        unless dec[4].empty?
          dec[4].each {|s|
            if s.size > 1 and s.first.start_with?('invisible_visit_')
              if ((visit_param = s.drop(1)) & f).empty?
                define_methods << "\n  if(applicable_const(visit#{visit_param.size}, #{terms_to_hyper(visit_param)})) return false;"
                visit_param = nil
              end
              break
            end
          } unless state_visit
          malloc = []
          dec[4].each_with_index {|s,i|
            define_methods << "\n  Task *subtask#{i} = new_task(#{s.size - 1});"
            malloc << "subtask#{i}"
          }
          define_methods << "\n  malloc_test(#{malloc.join(' && ')});"
        end
        close_method_str = ''
        indentation = "\n  "
        counter = -1
        # Lifted
        unless f.empty?
          ground = param.dup
          predicate_loops = []
          until precond_pos.empty?
            pre, *terms = precond_pos.shift
            equality.clear
            define_methods_comparison.clear
            new_grounds = false
            terms2 = terms.map {|j|
              if not j.start_with?('?')
                equality << "_#{j}_ground != t_#{j}"
                "_#{j}_ground"
              elsif ground.include?(j)
                equality << "#{j = j.tr('?','_')}_ground != #{j}"
                "#{j}_ground"
              else
                new_grounds = true
                ground << f.delete(j)
                j.tr('?','_')
              end
            }
            if new_grounds
              if predicates[pre]
                unless predicate_loops.include?(pre)
                  predicate_loops << pre
                  define_methods << "#{indentation}const auto #{pre}_ = state->#{pre}_;"
                end
                define_methods << "#{indentation}for(auto it#{counter += 1} = #{pre}_->begin(); it#{counter} != #{pre}_->end(); ++it#{counter})#{indentation}{"
              else
                define_methods << "#{indentation}return false;" unless state.include?(pre)
                pre = 'equal' if pre == '='
                define_methods << "#{indentation}for(auto it#{counter += 1} = #{pre}_.begin(); it#{counter} != #{pre}_.end(); ++it#{counter})#{indentation}{"
              end
              # close_method_str.prepend('}') and no indentation change for compact output
              close_method_str.prepend("#{indentation}}")
              indentation << '  '
              if terms2.size == 1 then define_methods << "#{indentation}VALUE #{terms2.first} = *it#{counter};"
              else terms2.each_with_index {|term,i| define_methods << "#{indentation}VALUE #{term} = std::get<#{i}>(*it#{counter});"}
              end
            elsif pre == '=' then equality << "#{terms2[0]} != #{terms2[1]}"
            elsif not predicates[pre] || state.include?(pre) then define_methods << "#{indentation}return false;"
            else define_methods_comparison << "#{indentation}if(!#{applicable(pre, terms, predicates, arity)}) continue;"
            end
            precond_pos.reject! {|pre,*terms|
              if (terms & f).empty?
                if pre == '=' then equality << "#{term(terms[0])} != #{term(terms[1])}"
                elsif not predicates[pre] || state.include?(pre) then define_methods << "#{indentation}return false;"
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
        if dec[4].empty? then define_methods << "#{indentation}yield(task->next, #{labels.size}, 0);#{close_method_str}\n  return false;\n}"
        else
          tasks_to_hyper(define_methods, dec[4], indentation)
          define_methods << "#{indentation}yield(subtask0, #{labels.size}, #{dec[4].count {|s,| !s.start_with?('invisible_')}});#{close_method_str}"
          malloc.each {|s| define_methods << "\n  free(#{s});"}
          define_methods << "\n  return false;\n}"
        end
        labels << dec[0]
        "#{name}_#{dec[0]}_(task)"
      }
      define_methods << "\n\nstatic bool #{name}_(const Task *task)\n{\n  return #{decompositions.join(' || ')};\n}"
    }
    # Definitions
    template = TEMPLATE.sub('<OPERATORS>', define_operators)
    template.sub!('<METHODS>', define_methods)
    visible = 0
    tokens = operators.map(&:first).sort_by! {|i| i.start_with?('invisible_') ? 1 : (visible += 1; 0)}.concat(methods.map(&:first))
    template.sub!('<INVISIBLE_BASE_INDEX>', visible.to_s)
    template.sub!('<METHODS_BASE_INDEX>', operators.size.to_s)
    template.sub!('<DOMAIN>', tokens.join("_,\n  "))
    tokens.concat(predicates.keys)
    operators.pop if invisible_goal
    # Start
    define_start = ''
    define_start_bits = ''
    define_state = ''
    define_state_bits = ''
    define_state_const = ''
    define_delete = []
    comparison = []
    predicates.each {|pre,type|
      k = state[pre]
      if type
        if (a = arity[pre]) == 0
          define_state_bits << "\n  VALUE0 #{pre}_;"
          define_start_bits << "\n  start.#{pre}_ = #{k ? true : false};"
        else
          define_state << "\n  VALUE#{a} *#{pre}_;"
          define_delete << "\n  if(old_state->#{pre}_ != state->#{pre}_) delete state->#{pre}_"
          define_start << "\n  start.#{pre}_ = new VALUE#{a}"
          if k
            define_start << "\n  {\n    #{k.map {|terms| terms_to_hyper(terms)}.join(",\n    ")}\n  }"
            tokens.concat(k.flatten(1))
          end
          define_start << ';'
        end
        comparison << pre
      elsif k
        if k.first.empty? then define_state_const << "\nstatic VALUE0 #{pre}_ = true;"
        else
          define_state_const << "\nstatic VALUE#{arity[pre] ||= k.first.size} #{pre == '=' ? 'equal' : pre}_\n{\n  #{k.map {|terms| terms_to_hyper(terms)}.join(",\n  ")}\n};"
          tokens.concat(k.flatten(1))
        end
      end
    }
    template.sub!('<STATE>', define_state << define_state_bits)
    if state_visit
      comparison.map! {|i| arity[i] == 0 ? "\n    if(a->#{i}_ != b->#{i}_) return a->#{i}_ < b->#{i}_;" : "\n    if(a->#{i}_ != b->#{i}_ && *a->#{i}_ != *b->#{i}_) return *a->#{i}_ < *b->#{i}_;"}
      define_state_const << "\n\nstruct state_cmp\n{\n  inline bool operator ()(const State *a, const State *b) const\n  {#{comparison.join}\n    return false;\n  }\n};"
      (state_visit + 1).times {|i| define_state_const << "\nstatic std::set<State*,state_cmp> state_visit#{i};"}
      template.slice!('<CLEAR>')
      template.slice!('<DELETE>')
    else
      define_visit.uniq!
      template.sub!('<CLEAR>', define_visit.map! {|i| define_state_const << "\nstatic VALUE#{i} visit#{i};"; "\n  visit#{i}.clear()"}.join('; \\'))
      template.sub!('<DELETE>', define_delete.join('; \\') << "; \\\n  free(state)")
    end
    template.sub!('<STATE_CONST>', define_state_const)
    template.sub!('<START>', define_start << define_start_bits)
    tasks.drop(1).each {|_,*terms| tokens.concat(terms)}
    goal_pos.each {|_,*terms| tokens.concat(terms)}
    goal_not.each {|_,*terms| tokens.concat(terms)}
    tokens.uniq! {|t| t.tr('-','_')}
    template.sub!('<TOKENS>', tokens.map {|t| t == '=' ? 'equal' : t}.join(",\n  t_"))
    template.sub!('<TOKEN_SIZE>', tokens.empty? ? '1' : (tokens.max_by(&:size).size + 1).to_s)
    template.sub!('<STRINGS>', tokens.join("\",\n  \""))
    template.sub!('<LABEL_SIZE>', labels.empty? ? '1' : (labels.max_by(&:size).size + 1).to_s)
    template.sub!('<LABELS>', labels.join("\",\n  \""))
    (arity = arity.values).uniq!
    arity.sort!
    arity.shift while arity[0]&.< 2
    template.sub!('<VALUE_TYPE>', tokens.size <= 256 ? 'char' : 'int')
    template.sub!('<VALUES>', arity.map! {|v| "\ntypedef std::set<std::tuple<#{Array.new(v,'VALUE').join(',')}>> VALUE#{v};"}.join)
    # Tasks
    if tasks.empty? then template.sub!('<TASK0>', 'NULL')
    else
      raise 'Unordered tasks not supported' unless ordered = tasks.shift
      define_tasks = ''
      malloc = []
      tasks.each_with_index {|s,i|
        define_tasks << "\n  Task *subtask#{i} = new_task(#{s.size - 1});"
        malloc << "subtask#{i}"
      }
      tasks_to_hyper(define_tasks << "\n  malloc_test(#{malloc.join(' && ')});", tasks, "\n  ", 'NULL')
      tasks.unshift(ordered)
      tasks.pop if invisible_goal
      template.sub!('<TASKS>', define_tasks)
      template.sub!('<TASK0>', 'subtask0')
    end
    template.sub!('<NTASKS>', (tasks.size - 1).to_s)
    template.gsub!(/\b-\b/,'_')
    template
  end

  #-----------------------------------------------
  # Compile problem
  #-----------------------------------------------

  def compile_problem(domain_name, problem_name, operators, methods, predicates, state, tasks, goal_pos, goal_not, domain_filename)
  end

  TEMPLATE =
'// Generated by Hype
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <set>
#include <tuple>

#define STACK 5000

#define INVISIBLE_BASE_INDEX <INVISIBLE_BASE_INDEX>
#define METHODS_BASE_INDEX <METHODS_BASE_INDEX>
#define DOMAIN_SIZE (sizeof(domain) / sizeof(*domain))
#define applicable(predicate, value) (state->predicate->find(value) != state->predicate->end())
#define applicable_const(predicate, value) (predicate.find(value) != predicate.end())
#define new_task(parameters) (Task *) malloc(sizeof(Task) + sizeof(VALUE) * (parameters))
#define new_state()                                   \
  State *new_state = (State *) malloc(sizeof(State)); \
  malloc_test(new_state);                             \
  memcpy(new_state, state, sizeof(State));            \
  state = new_state

#define visit_clear() \<CLEAR>

#define delete_state() \<DELETE>

#ifndef IPC

#define yield(subtasks, label, ntasks) \
  Task *plan = planning(subtasks);     \
  if(plan)                             \
  {                                    \
    next_plan = plan;                  \
    return true;                       \
  }

#else

#define yield(subtasks, label, ntasks) \
  unsigned int new_index = tindex, old_index = tindex - ntasks; \
  Task *plan = planning(subtasks);     \
  if(plan)                             \
  {                                    \
    decomposition.push_back({task, label, old_index, new_index}); \
    next_plan = plan;                  \
    return true;                       \
  }                                    \
  tindex = old_index;

#endif

#ifdef DEBUG
#define error(m) {puts(m); exit(EXIT_FAILURE);}
#else
#define error(m) exit(EXIT_FAILURE)
#endif

#define malloc_test(condition) if(!(condition)) error("Malloc error")

// Tokens
enum {
  t_<TOKENS>
};

static const char tokens[][<TOKEN_SIZE>] = {
  "<STRINGS>"
};

static const char labels[][<LABEL_SIZE>] = {
  "<LABELS>"
};

typedef unsigned <VALUE_TYPE> VALUE;
typedef bool VALUE0;
typedef std::set<VALUE> VALUE1;<VALUES>

static bool nostack;
static struct Task
{
  Task *next;
#ifdef IPC
  unsigned int index;
#endif
  VALUE value;
  VALUE parameters[1];
} *next_plan, empty;

static struct State
{<STATE>
} *state;
<STATE_CONST>
static Task* planning(Task *tasks);

#ifdef IPC

#include <vector>
struct Taskout {const Task *task; unsigned int label, min, max;};
static std::vector<Taskout> decomposition;
static unsigned int tindex;
#define tindex(task) task->index = tindex++

#else
#define tindex(task)
#endif

//-----------------------------------------------
// Operators
//-----------------------------------------------<OPERATORS>

//-----------------------------------------------
// Methods
//-----------------------------------------------<METHODS>

static bool (*domain[])(const Task *) = {
  <DOMAIN>_
};

static void print_task(const Task *task)
{
  fputs(tokens[task->value], stdout);
  for(VALUE i = 1; i <= task->parameters[0]; ++i)
  {
    putchar(\' \');
    fputs(tokens[task->parameters[i]], stdout);
  }
  putchar(\'\n\');
}

static void print_sequence(unsigned int min, unsigned int max)
{
  do
  {
    printf(" %u", min);
  } while(++min < max);
  putchar(\'\n\');
}

static Task* planning(Task *tasks)
{
  // Empty tasks
  if(!tasks)
  {
#ifdef DEBUG
    puts("Empty tasks");
#endif
    return &empty;
  }
  static unsigned int level;
#ifdef STACK
  if(level > STACK)
  {
    nostack = true;
    return NULL;
  }
#endif
#ifdef DEBUG
  if(tasks->value >= DOMAIN_SIZE)
  {
    printf("Domain defines no decomposition for index %u\n", tasks->value);
    exit(EXIT_FAILURE);
  }
  printf("%u: %u %p\n", level, tasks->value, tasks->next);
  print_task(tasks);
#endif
  ++level;
  // Operator
  if(tasks->value < METHODS_BASE_INDEX)
  {
    State *old_state = state;
    if(domain[tasks->value](tasks))
    {
      Task *plan = planning(tasks->next);
      if(plan)
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
        delete_state();
      }
    }
    state = old_state;
  }
  // Method
  else if(domain[tasks->value](tasks))
  {
    return next_plan;
  }
  --level;
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
  puts("Planning");
  Task *result = planning(<TASK0>);
  // Print plan
  if(result)
  {
#ifdef IPC
    puts("==>");
#endif
    if(result == &empty)
    {
#ifndef IPC
      puts("Empty plan");
#endif
    }
    else
    {
      do
      {
#ifdef IPC
        printf("%u ", result->index);
#endif
        print_task(result);
        result = result->next;
      } while(result != &empty);
    }
#ifdef IPC
    fputs("root", stdout);
    print_sequence(0, <NTASKS>);
    unsigned int size = decomposition.size();
    while(size--)
    {
      const Task *task = decomposition[size].task;
      printf("%u ", task->index);
      fputs(tokens[task->value], stdout);
      for(VALUE i = 1; i <= task->parameters[0]; ++i)
      {
        putchar(\' \');
        fputs(tokens[task->parameters[i]], stdout);
      }
      fputs(" -> ", stdout);
      fputs(labels[decomposition[size].label], stdout);
      print_sequence(decomposition[size].min, decomposition[size].max);
    }
    puts("<==");
#endif
    return EXIT_SUCCESS;
  }
  puts(nostack ? "Planning failed, try with more STACK" : "Planning failed");
  return EXIT_FAILURE;
}'
end