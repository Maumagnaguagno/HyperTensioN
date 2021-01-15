# HyperTensioN [![Build Status](https://travis-ci.org/Maumagnaguagno/HyperTensioN.svg)](https://travis-ci.org/Maumagnaguagno/HyperTensioN) [![Actions Status](https://github.com/Maumagnaguagno/HyperTensioN/workflows/build/badge.svg)](https://github.com/Maumagnaguagno/HyperTensioN/actions) [![IPC](https://img.shields.io/badge/HTN%20IPC%202020%20Total%20Order%20track-winner-D50.svg)](http://gki.informatik.uni-freiburg.de/competition/results.pdf)
**Hierarchical Task Network planning in Ruby**

HyperTensioN is a [Hierarchical Task Network](https://en.wikipedia.org/wiki/Hierarchical_task_network) planner written in Ruby.
With hierarchical planning it is possible to describe recipes about how and when to execute actions to accomplish tasks.
These recipes describe how tasks can be decomposed into subtasks, refined until only actions remain, the plan.
This is very alike to how humans think, taking mental steps further into primitive operators.
HTN is also used as an acronym for Hypertension in medical context, therefore the name was given.
In order to support multiple [action description languages](https://en.wikipedia.org/wiki/Action_description_language) a module named [Hype](#hype "Jump to Hype section") takes care of the conversion process.
Expanded features to deal with numeric and external elements are in a separate repository, [HyperTensioN U](../../../HyperTensioN_U).
[Hypertension won the HTN IPC 2020 Total order track!](docs/IPC.md)
This project was inspired by [Pyhop] and [JSHOP].

[Download and play](../../archive/master.zip) or jump to each section to learn more:
- [**Algorithm**](#algorithm "Jump to Algorithm section"): planning algorithm explanation
- [**API**](#api "Jump to API section"): Variables and methods defined by HyperTensioN
- [**Getting started**](#getting-started "Jump to Getting started section"): Features explained while describing a domain with HyperTensioN
- [**Hype**](#hype "Jump to Hype section"): Follow the Hype and let domain and problem be converted and executed automagically
- [**Hints**](#hints "Jump to Hints section"): a list of hints to keep in mind
- [**Comparison**](#comparison "Jump to Comparison section"): A brief comparison with JSHOP and Pyhop
- [**Changelog**](#changelog "Jump to Changelog section"): a small list of things that happened
- [**ToDo's**](#todos "Jump to ToDo's section"): a small list of things to be done

## Algorithm
The basic algorithm for HTN planning is quite simple and flexible, the hard part is in the structure that decomposes a hierarchy and the unification engine.
The task list (input of planning) is decomposed until nothing remains, the base of recursion, returning an empty plan.
The tail of recursion are the operator/primitive task and method/compound task cases.
The operator tests if the current task (the first in the list, since it decomposes in order here) can be applied to the current state (which is a visible structure to the other Ruby methods, but does not appear here).
If successfully applied, the planning process continues decomposing and inserting the current task at the beginning of the plan, as it builds the plan during recursion from last to first.
If it is a method it is decomposed into one of several cases with a valid unification for the free variables.
Each case unified is a list of tasks, subtasks, that may require decomposition too, replacing the original method.
Only methods accept unification of free variables, although it could also unify operators (but they would not be that primitive anymore).
Methods take care of the heavy part (should the _agent_ **move** from _here_ to _there_ by **foot** ``[walking]`` or call a **cab** ``[call, enter, ride, pay, exit]``) while the operators just execute the effects when applicable.
If no decomposition is possible, failure is returned.

```Ruby
Algorithm planning(list tasks)
  return empty plan if tasks = empty
  current_task <- shift element from tasks
  if current_task is an Operator
    if applicable(current_task)
      apply(current_task)
      plan <- planning(tasks)
      if plan
        plan <- current_task + plan
        return plan
      end
    end
  else if current_task is a Method
    for methods in decomposition(current_task)
      for subtasks in unification(methods)
        plan <- planning(subtasks + tasks)
        return plan if plan
      end
    end
  end
  return Failure
end
```

## API
[**Hypertension**](Hypertension.rb) is a module with 3 attributes:
- ``attr_accessor :state`` with the current state.
- ``attr_accessor :domain`` with the decomposition rules that can be applied to the operators and methods.
- ``attr_accessor :debug`` as a flag to print intermediate data during planning.

They were defined as instance variables to be mixed in other classes if needed, that is why they are not class variables.

```Ruby
# Require and use
require './Hypertension'

Hypertension.state = [...]
Hypertension.applicable?(...)
```

```Ruby
# Mix in
require './Hypertension'

class Foo < Bar
  include Hypertension

  def method(...)
    @state = [...]
    applicable?(...)
  end
end
```

Having the state and domain as separate variables also means there is no need to propagate them.
This also means that at any point one can change more than the state.
This may be useful to reorder method decompositions in the domain to modify the behavior without touching the methods or set the debug option only after an specific operator is called.
The plan is created during backtracking, which means there is no mechanism to reorder actions in the planning process, but it is possible with a variation that creates the plan during decomposition.

The methods are few and simple to use:
- ``planning(tasks, level = 0)`` receives a task list, ``[[:task1, 'term1', 'term2'], [:task2, 'term3']]``, to decompose and the nesting level to help debug.
Only call this method after domain and state were defined.
This method is called recursively until it finds an empty task list, ``[]``, then it starts to build the plan while backtracking to save CPU (avoid intermediate plan creation).
Therefore no plan actually exists before reaching an empty task list.
In case of failure, ``nil`` is returned.

- ``applicable?(precond_pos, precond_not)`` tests if the current state have all positive preconditions and not a single negative precondition. Returns ``true`` if applicable, ``false`` otherwise.
- ``apply(effect_add, effect_del)`` modifies the current state, add or remove predicates present in the lists. Returns ``true``.
- ``apply_operator(precond_pos, precond_not, effect_add, effect_del)`` applies effects if ``applicable?``. Returns ``true`` if applied, ``nil`` otherwise.
- ``generate(precond_pos, precond_not, *free)`` yields all possible unifications to the free variables defined, therefore a block is needed to capture the unifications. Return value is undefined.
- ``print_data(data)`` can be used to print task and predicate lists, useful for debug.
- ``problem(state, tasks, debug = false, &goal)`` simplifies the setup of a problem instance, returns the value of planning. Use problem as a template to see how to add HyperTensioN in a project.
- ``task_permutations(state, tasks)`` tries several task permutations to achieve unordered decomposition, it is used by ``problem`` when a goal block is provided. Returns a plan or ``nil``.

Domain operators can be defined without ``apply_operator`` and will have the return value considered.
- ``false`` or ``nil`` means the operator has failed.
- Any other value means the operator was applied with success.

Domain methods must yield a task list or are nullified, having no decomposition.

## Getting started
The idea is to [``include Hypertension`` in the domain module](#api "Jump to API section"), define the methods and primitive operators, and use this domain module for different problems.
Problems may be in a separate file or generated during run-time.
Since HyperTensioN uses **metaprogramming**, there is a need to specify which Ruby methods may be used by the [planner](#algorithm "Jump to Algorithm section").
This specification declares operator visibility and the subtasks of each method in the domain structure.

### Example
Here the [Rescue Robot Robby domain](examples/robby "Robby folder") is used as a domain example.
In this domain a rescue robot is called to action.
The robot is inside an office building trying to check the status of certain locations.
Those locations are defined by the existence of a beacon, and the robot must be in the same hallway or room as each beacon to check its status.
Robby has a small set of actions available to do so:
- **Enter** a room connected to the current hallway
- **Exit** the current room to a connected hallway
- **Move** from hallway to hallway
- **Report** status of beacon in the current room or hallway

This is the set of primitive operators, enough for classical planning, but not for HTN planning.
Recipes are needed to connect such operators, and for HTN planning the recipes will be defined in a hierarchical structure.
Robby must move, enter and exit zero or more times to reach each beacon to report, and repeat the process for every other beacon.
The recipe is quite similar to the following regular expression:

```Ruby
/((move|enter|exit)*report)*/
```

Easier to start with the movement operators, the tricky part is to avoid repetitions or the robot may be stuck in a loop of A to B and B to A during [search](examples/search/search.jshop).
Robby needs to remember which locations were visited using a recursive description.
The base of the recursion happens when the object (Robby) is already at the destination, otherwise use move, enter or exit, mark the position and call the recursion again.
Locations must be unvisited once the destination is reached to be able to reuse such locations.

### Domain
The first step is to define all the nodes in the hierarchy.
The nodes include the basic operators, visit, unvisit and one method to swap positions defined by the **at** predicate:

```Ruby
require '../../Hypertension'

module Robby
  include Hypertension
  extend self

  @domain = {
    # Operators
    :enter => true,
    :exit => true,
    :move => true,
    :report => true,
    :visit_at => false,
    :unvisit_at => false,
    # Methods
    :swap_at => [
      :swap_at__base,
      :swap_at__recursion_enter,
      :swap_at__recursion_exit,
      :swap_at__recursion_move
    ]
  }
end
```

The operators are the same as before, but visit and unvisit are not really important outside the planning stage, therefore they are not visible (``false``), while the others are visible (``true``).
The movement method ``swap_at`` is there, without any code describing its behavior, only the available methods.
This is equivalent to header files holding function prototypes.
Each ``swap_at__XYZ`` method describes one possible case of decomposition of ``swap_at``
It is also possible to avoid listing all of them and filter based on their name (after they were declared):

```Ruby
@domain[:swap_at] = instance_methods.find_all {|method| method =~ /^swap_at/}
```

The enter operator appears to be a good starting point to define preconditions and effects.
Easier to see what is changing using a table:

Enter | bot source destination
--- | ---
***Preconditions*** | ***Effects***
(robot bot) |
(hallway source) |
(room destination) |
(connected source destination) |
(at bot source) | **not** (at bot source)
**not** (at bot destination) | (at bot destination)

Which translates to the following Ruby code:

```Ruby
def enter(bot, source, destination)
  apply_operator(
    # Positive preconditions
    [
      [ROBOT, bot],
      [HALLWAY, source],
      [ROOM, destination],
      [AT, bot, source],
      [CONNECTED, source, destination]
    ],
    # Negative preconditions
    [
      [AT, bot, destination]
    ],
    # Add effects
    [
      [AT, bot, destination]
    ],
    # Del effects
    [
      [AT, bot, source]
    ]
  )
end
```

The application of an operator creates a new state if the preconditions are satisfied, which requires a state copy (a costly operation).
One can avoid ``apply_operator`` and handle this process.
It is possible to create dummy operators that simulate success or failure without state modifications, returning ``true`` or ``false``.
Success may be useful during the debug process or to change an internal feature of the agent wrapping the HTN when parsing the plan returned.
Failure can be used to destroy the current plan decomposition without the use of preconditions, a specific case in which this construct is useful is not know.

```Ruby
def success(term1, term2)
  true
end

def failure(term1, term2)
  false
end

def set_debug(term)
  @debug = term
  true # Otherwise term is returned
end
```

The other operators are no different, time to see how ``swap_at`` method works.
Every case is defined as a different method.
The order they appear in the domain definition implies the order of evaluation.
Methods may appear in 3 different scenarios:
- **No preconditions**, direct application of subtasks.
- **Ground preconditions**, apply subtasks if satisfied, every term is a [ground term](https://en.wikipedia.org/wiki/Ground_expression).
- **Lifted preconditions**, unify [free variables](https://en.wikipedia.org/wiki/Free_variables_and_bound_variables) according to the preconditions. [Check how it works](#free-variables).

Instead of returning, the methods yield a subtask list.
This approach solves the problem of returning several unifications per method call, yielding them as required.
Be aware that all methods must have the same parameter list, other variables must be bound during run-time (**Lifted preconditions**).

#### No preconditions
This is the simplest case, the method **yields** a subtask list without any test.
The subtask list may be empty, ``yield []``.
This example is not part of the current implementation of Robby.

```Ruby
def swap_at__jump(object, goal)
    yield [
      [:jump, object]
    ]
  end
end
```

#### Ground preconditions
Sometimes unique preconditions appear in the last operator of the subtask list.
One wants to discover if such preconditions are satisfied before the execution of several steps to discover if this decomposition leads to a failure.
Use preconditions as look-aheads, this may create a redundancy with the operators, but saves quite a lot of time if used wisely.

```Ruby
def swap_at__base(object, goal)
  if applicable?(
    # Positive preconditions
    [
      [AT, object, goal]
    ],
    # Negative preconditions
    []
  )
    yield [
      [:unvisit_at, object]
    ]
  end
end
```

#### Lifted preconditions
It is impossible to propagate variables all the time, some variables must be bound during run-time.
Free variables are created as empty strings, being used as pointers to their future values.
A ``generate(precond_pos, precond_not, *free)`` method will do the hard work, using positive preconditions to find possible values for the free variables, only yielding values that satisfy the preconditions requested.
Therefore a positive precondition set that does not mention all free variables will generate zero unifications.
In classical planning it is possible to try the entire list of objects as values, but in HTN there may be an infinite number of values.
It is possible to solve this problem adding each object possible to be used to the initial state, ``(object kiwi) (object banjo)``, in the initial state and add them in the preconditions, ``(object ?x)``.
Unifications only happen to methods in HyperTensioN, a method must be created to bound values for an operator if a free variable value is not know.
The following example goes beyond this specification, using an instance variable to avoid cached positions created by other decomposition paths.
One can always use ``if-else`` constructs to speed-up problem solving.
Here it is clear that no state memory is created by HyperTensioN, that is why ``@visited_at`` is used.
This memory is also cleared during the process to reuse previous positions, give a look at visit and unvisit operators in Robby to understand.
Visit and unvisit can also be defined as predicates, but then memory would only hold the current path, which makes planning slower.

```Ruby
def swap_at__recursion_enter(object, goal)
  # Free variables
  current = ''
  intermediate = ''
  # Generate unifications
  generate(
    # Positive preconditions
    [
      [AT, object, current],
      [CONNECTED, current, intermediate]
    ],
    # Negative preconditions
    [
      [AT, object, goal]
    ], current, intermediate
  ) {
    unless @visited_at[object].include?(intermediate)
      yield [
        [:enter, object, current, intermediate],
        [:visit_at, object, current],
        [:swap_at, object, goal]
      ]
    end
  }
end
```

#### Free Variables?
Free variables are not natively supported by Ruby.
A free variable works like a placeholder, once bound it will have a value like any common variable.
The binding process requires the context to dictate possible values to the variable.
In Ruby, the content of a string can be replaced with a value, but that requires the creation of the original string with any value to be used as a pointer, or a more complex solution involving ``method_missing`` to tell the interpreter to create variables if none is found.
Here the empty strings represent free variables, ``my_var = ''``.
One can use the ``free_variable`` method for verbosity reasons with a minimal overhead.

```Ruby
def free_variable
  ''
end

my_var = free_variable
```

Free variables can also be defined as arguments, no problem.
Free variables must be defined and passed to generate, this avoids the step of searching on every precondition which variables are empty.
The refactored example looks like this:

```Ruby
def swap_at__recursion_enter(object, goal, current = free_variable, intermediate = free_variable)
  # Generate unifications
  generate(
    # Positive preconditions
    [
      [AT, object, current],
      [CONNECTED, current, intermediate]
    ],
    # Negative preconditions
    [
      [AT, object, goal]
    ], current, intermediate
  ) {
    block_removed
  }
end
```

### Problem
With the domain ready it is time the problem, with an initial state and task list.
The initial state is defined as an Array in which each index represent one predicate while the value is an array of possible terms.
The task list follows the same principle, an array of each task to be solved.
Note that the names must match the ones defined in the domain and tasks are be decomposed in the same order they are described (in ordered mode).
Even predicates that do not appear in the initial state must be declared, in this example nothing is reported so ``state[REPORTED]`` is declared as ``[]``.
If the problem does not generate objects during run-time a speed improvement can be obtained moving them to constants, therefore the comparisons will be pointer-based.
It is possible to activate debug mode with a command line argument, in this case ``ruby pb1.rb debug``.

```Ruby
require './Robby'

# Predicates
AT = 0
IN = 1
CONNECTED = 2
ROBOT = 3
OBJECT = 4
LOCATION = 5
HALLWAY = 6
ROOM = 7
BEACON = 8
REPORTED = 9

# Objects
robby = 'robby'
left = 'left'
middle = 'middle'
right = 'right'
room1 = 'room1'
beacon1 = 'beacon1'

Robby.problem(
  # Start
  [
    [ [robby, left] ], # AT
    [ [beacon1, room1] ], # IN
    [ # CONNECTED
      [middle, room1],  [room1, middle],
      [left, middle],   [middle, left],
      [middle, right],  [right, middle]
    ],
    [ [robby] ], # ROBOT
    [ [robby], [beacon1] ], # OBJECT
    [ [left], [middle], [right], [room1] ], # LOCATION
    [ [left], [middle], [right] ], # HALLWAY
    [ [room1] ], # ROOM
    [ [beacon1] ], # BEACON
    [] # REPORTED
  ],
  # Tasks
  [
    [:swap_at, robby, room1],
    [:report, robby, room1, beacon1],
    [:swap_at, robby, right]
  ],
  # Debug
  ARGV.first == 'debug'
)
```

The problem acts as the main function since the problem include the domain, and the domain include the planner.
To execute the problem 1 of Robby:

```Shell
cd HyperTensioN
ruby examples/robby/pb1.rb
```

A domain and problem already described in [PDDL], [HDDL] or [JSHOP] description must first be converted to Ruby, which is a task for [Hype](#hype "Jump to Hype section").

## Hype
[**Hype**](Hype.rb) is the framework for parsers, extensions and compilers of planning descriptions.
It will save time and avoid errors during conversion of domains and problems for comparison results with other planners.
Such conversion step is not new, as JSHOP2 itself compiles the description to Java code to achieve a better performance.
Hype requires a domain and a problem files with the correct extension type to be parsed correctly, while the output type must be specified to match a compiler.
If no output type is provided the system uses the default ``print`` to show what was parsed from the files and the time taken.
Multiple extensions can be executed before the output happens, even repeatedly.

```
Usage:
  Hype domain problem {extensions} [output=print]

Output:
  print - print parsed data(default)
  rb    - generate Ruby files to HyperTensioN
  pddl  - generate PDDL files
  jshop - generate JSHOP files
  dot   - generate DOT file
  md    - generate Markdown file
  run   - same as rb with execution
  debug - same as run with execution log
  nil   - avoid print parsed data

Extensions:
  patterns    - add methods and tasks based on operator patterns
  dummy       - add brute-force methods to operators
  dejavu      - add invisible visit operators
  wise        - warn and fix description mistakes
  macro       - optimize operator sequences
  pullup      - optimize preconditions
  typredicate - optimize typed predicates
  grammar     - print hierarchical structure grammar
  complexity  - print estimated complexity of planning description
```

To convert and execute the Basic example is simple, compile once and execute multiple times the compiled output.

```Shell
cd HyperTensioN
ruby Hype.rb examples/basic/basic.jshop examples/basic/pb1.jshop rb
ruby examples/basic/pb1.jshop.rb
```

One can compile and execute in a single command with ``run``, the system compile as ``rb`` and require the generated files.
Activate debug mode with ``debug`` to pass the debug flag to the problem and show explored paths instead of only the planning result.

```Shell
ruby Hype.rb examples/basic/basic.jshop examples/basic/pb1.jshop run
ruby Hype.rb examples/basic/basic.jshop examples/basic/pb1.jshop debug
```

Hype is composed of:

**Parsers**:
- [PDDL]
- [JSHOP]
- [HDDL]

**Extensions**:
- Patterns (add methods based on operator patterns, map goal state to tasks)
- [Dummy](docs/Dummy.md) (add brute-force methods that try to achieve goal predicates)
- Dejavu (add invisible visit/unvisit operators to avoid repeated decompositions)
- Wise (warn and fix description mistakes)
- Macro (optimize operator sequences to speed up decomposition)
- Pullup (optimize preconditions to avoid backtracking)
- Typredicate (optimize typed predicates)
- Grammar (print domain methods as [production rules](https://en.wikipedia.org/wiki/Production_(computer_science)))
- Complexity (print domain, problem and total complexity based on amount of terms)

**Compilers**:
- HyperTensioN (methods and tasks are unavailable for a PDDL input without extensions)
- [PDDL] (methods are ignored, goal must be manually converted based on tasks)
- [JSHOP] (methods and tasks are unavailable for a PDDL input without extensions)
- [Graphviz DOT](http://www.graphviz.org/) (generate a [graph](docs/Graph.md) description to be compiled into an image)
- [Markdown](https://daringfireball.net/projects/markdown/)

As any parser, the ones provided by Hype are limited in one way or another.
[PDDL] has far more features than supported by most planners and [JSHOP] have 2 different ways to define methods.
Methods may be broken into several independent blocks or in the same block without the need to check the same preconditions again.
Both cases are supported, but HyperTensioN evaluates the preconditions of each set independently while [JSHOP] only evaluates the last if the previous ones evaluated to false in the same block.
In order to copy this behavior one would need to declare the methods in the same Ruby method (losing label definition), which could decrease readability.
[JSHOP] axioms and external calls are not supported, such features are part of [HyperTensioN U](../../../HyperTensioN_U).

One can always not believe the Hype and convert descriptions manually, following a style that achieves a better or faster solution.
Counters in methods can be used to return after generate unified a certain amoung of times a specific value.
It is possible to support [JSHOP] behavior putting several generators in one method and returning if the previous one ever unified.
Hype can do most of the boring optimizations so one can focus on the details.

### Parsers
Parsers are modules that read planning descriptions and convert the information to an [Intermediate Representation].
The basic parser is a module with two methods that fill the planning attributes:

```Ruby
module Foo_Parser
  extend self

  attr_reader :domain_name, :problem_name, :operators, :methods, :predicates, :state, :tasks, :goal_pos, :goal_not

  def parse_domain(domain_filename)
    description = IO.read(domain_filename)
    # TODO fill attributes
  end

  def parse_problem(problem_filename)
    description = IO.read(problem_filename)
    # TODO fill attributes
  end
end
```

With the parser completed, it needs to be connected with Hype based on the file extensions of the files provided.
It is expected that domain and problem files have the same extension to avoid incomplete data from mixed inputs.
The parser is responsible for file reading to allow uncommon, but possible, binary files.
Since parsers create structures no value is expected to be returned by ``parse_domain`` and ``parse_problem``.

### Extensions
Extensions are modules that analyze or transform planning descriptions in the [Intermediate Representation] format.
The basic extension is a module with one method to extend the attributes obtained from the parser:

```Ruby
module Extension
  extend self

  def apply(operators, methods, predicates, state, tasks, goal_pos, goal_not)
    # TODO modify attributes
  end
end
```

Extensions are supposed to be executed between the parsing and compilation phases.
More than one extension may be executed in the process, even repeatedly.
They can be used to clean, warn and fill gaps left by the original description.
Since extensions transform existing structures, the value returned by ``apply`` is undefined.

### Compilers
Compilers are modules that write planning descriptions based on the information available in the [Intermediate Representation] format.
The basic compiler is a module with two methods to compile problem and domain files to text:

```Ruby
module Bar_Compiler
  extend self

  def compile_domain(domain_name, problem_name, operators, methods, predicates, state, tasks, goal_pos, goal_not)
    # TODO return string or nil, nil generates no output file
  end

  def compile_problem(domain_name, problem_name, operators, methods, predicates, state, tasks, goal_pos, goal_not, domain_filename)
    # TODO return string or nil, nil generates no output file
  end
end
```

Unlike parsers, ``compile_domain`` and ``compile_problem`` have a choice in their output.
The first option is for uncommon outputs, they must be handled inside the methods and return ``nil``.
The second option is to return a string to be written to a common text file.
If the second option was selected the output filename is the input filename with the new extension appended, therefore ``input.pddl`` to ``jshop`` would be ``input.pddl.jshop``, so no information about the source is lost.
Any compiler have access to the parser attributes, which means one module can optimize before another compiles.
In fact this is the core idea behind Hype, be able to parse, modify and compile domains without having to worry about language support.
Future languages compatible with the [Intermediate Representation] format could be supported by just adding a new parser and compiler.
The compiler is expected to not modify any parameter, use an extension to achieve such result.

## Hints
Here are some hints to describe a domain:
- Reuse objects in variables to compare faster (pointer comparison), only works for constant objects.
- Use Symbols or constant frozen Strings, avoid repeated Strings in memory.
- Check the method decomposition order, otherwise time will be lost before decomposing to the correct path.
- Use preconditions wisely, no need to test twice using a smart method decomposition, check out [And-or Trees](https://en.wikipedia.org/wiki/And%E2%80%93or_tree).
- Unifications are costly, avoid generate, match values once and propagate or use a custom unification process.
- Declare even empty preconditions and effects, use ``[]``.
- Empty predicate arrays must be declared in the initial state at the problem file. This avoids predicate typos, as all predicates must be previously defined.
- Explore further using ``Hash.compare_by_identity`` on domain.
- Use different state structures to speed-up state operations and implement custom state duplication, applicable and apply operations to better describe the domain.
- Replace the state copy from ``apply`` with ``@state = Marshal.load(Marshal.dump(@state))`` to deep copy any state structure, otherwise keep the current fast version or use a custom implementation.
- Increase ``RUBY_THREAD_VM_STACK_SIZE`` to avoid stack overflows in very large planning instances.
- Execute the interpreter with the ``--disable=all`` flag to load it faster.

## Comparison
The main advantage of HyperTensioN is to be able to define behavior in the core language, without losing clarity, this alone gives a lot of power.
JSHOP2 requires the user to dive into a very complex structure to unlock such power, while [Pyhop] is based on this feature, with everything defined in Python, but does not support backtracking and unification.
Without unification the user must ground or propagate variables by hand, and without backtracking the domain must never reach a dead-end during decomposition.
HyperTensioN biggest advantage is not the planner itself, but the parsers, extensions and compilers built around it, so that descriptions can be converted automatically.
Perhaps the most invisible advantage is the lack of custom classes, every object used during planning is defined as one of the core objects.
Once Strings, Symbols, Arrays and Hashes are understood, the entire HyperTensioN module is just a few methods away from complete understanding.

Among the lacking features is lazy variable evaluation and interleaved/unordered execution of tasks, a feature that JSHOP2 supports and important to achieve good plans in some cases.
Unordered tasks are supported only at the problem level and are not interleaved during decomposition.
Since explicit goals are tested only after the plan has been found with a sequence of tasks, a failure is considered enough proof to try other orderings, not other unifications with the same sequence of tasks.

## Changelog
- Mar 2014
  - First version based on Pyhop/JSHOP
  - Data structures modified
- Jun 2014
  - Add elements from ND_Pyhop
  - Data structures modified
  - Using previous state for state_valuation
  - Added support for minimum probability
  - Data structure simplified
  - Override state_valuation and state_copy for specific purposes
- Dec 2014
  - Forked project, probability mode only works for Hypertension_simple
  - STRIPS style operator application instead of imperative mode
  - Backtrack support
  - Operator visibility
  - Unification
  - Plan is built after tasks solved
  - Domain and problem separated
  - Deep copy only used at operator application
- Mar 2015
  - Refactoring of generate
- Jun 2015
  - Unordered tasks with explicit goal check
- Sep 2015
  - Apply method extracted from apply_operator
- Mar 2016
  - Released version 1.0
- Nov 2017
  - Faster state duplication
- Jun 2018
  - Always restore state after backtracking
- Sep 2019
  - Ignore irrelevant predicates during compilation
- Mar 2020
  - HDDL support
- May 2020
  - Add Pullup extension
  - New state representation
- Jul 2020
  - State no longer contains rigid predicates
  - Add Typredicate extension
- Aug 2020
  - Exit code based on problem return value
  - Add Dejavu extension and cache mechanism
- Oct 2020
  - Rescue infinite recursion stack overflow
- Nov 2020
  - Released version 2.0

## ToDo's
- Unordered subtasks
- Anytime mode
- Debugger (why is the planner not returning the expected plan?)
- More tests

[Intermediate Representation]: docs/Representation.md
[PDDL]: https://en.wikipedia.org/wiki/Planning_Domain_Definition_Language "PDDL at Wikipedia"
[JSHOP]: https://www.cs.umd.edu/projects/shop/description.html "SHOP/JSHOP project page"
[HDDL]: http://gki.informatik.uni-freiburg.de/papers/hoeller-etal-aaai20.pdf "HDDL paper"
[Pyhop]: https://bitbucket.org/dananau/pyhop "Pyhop project page"