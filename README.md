# HyperTensioN [![Build Status](https://travis-ci.org/Maumagnaguagno/HyperTensioN.svg)](https://travis-ci.org/Maumagnaguagno/HyperTensioN)
**Hierarchical Task Network planning in Ruby**

Hypertension is an [Hierarchical Task Network](https://en.wikipedia.org/wiki/Hierarchical_task_network) Planner written in Ruby, which means a description of how tasks can be accomplished using method decomposition is required to achieve a plan.
HTN is used as an acronym for Hypertension in medical context, therefore the name was given.
In order to support other planning languages a module named **[Hype](#hype "Jump to Hype section")** will take care of the conversion process.
With hierarchical planning it is possible to describe a strategy to obtain a sequence of actions that executes a certain task.
It works based on decomposition, which is very alike to how humans think, taking mental steps further into primitive operators.
This project was inspired by [Pyhop] and [JSHOP].

[Download and play](../../archive/master.zip) or jump to each section to learn more:
- [**Algorithm**](#algorithm "Jump to Algorithm section"): planning algorithm explanation.
- [**Getting started**](#getting-started "Jump to Getting started section"): Features explained while describing a domain with Hypertension.
- [**Hints**](#hints "Jump to Hints section"): a list of hints to keep in mind.
- [**Execution**](#execution "Jump to Execution section"): Command-line examples for the forgotten.
- [**API**](#api "Jump to API section"): Variables and methods defined by Hypertension.
- [**Hype**](#hype "Jump to Hype section"): Follow the Hype and let domain and problem be converted and executed automagically.
- [**Comparison**](#comparison "Jump to Comparison section"): A brief comparison with JSHOP and Pyhop.
- [**Changelog**](#changelog "Jump to Changelog section"): a small list of things that happened.
- [**ToDo's**](#todos "Jump to ToDo's section"): a small list of things to be done.

## Algorithm
The basic algorithm for HTN planning is quite simple and flexible, the hard part is in the structure that decomposes an hierarchy and the unification engine.
The task list (input of planning) is decomposed until nothing remains, the base of recursion, returning an empty plan.
The tail of recursion are the operator and method cases.
The operator tests if the current task (the first in the list, since it decomposes in order here) can be applied to the current state (which is a visible structure to the other Ruby methods, but does not appear here).
If successfully applied, the planning process continues decomposing and inserting the current task at the beginning of the plan, as it builds the plan during recursion from last to first.
If it is a method, the path is different, we need to decompose into one of several cases with a valid unification for the free variables.
Each case unified is a list of tasks, subtasks, that may require decomposition too, occupying the same place the method that generated them once was.
I exposed the unification only to methods, but it is possible to expose to operators too (which kills the idea of what a primitive is).
Now the methods take care of the heavy part (should the _agent_ **move** from _here_ to _there_ by **foot** ``[walking]`` or call a **cab** ``[call, enter, ride, pay, exit]``) while the primitive operators just execute the effects when applicable.
If no decomposition happens, failure is returned.

```Ruby
Algorithm planning(list tasks)
  return empty plan if tasks = empty
  current_task <- pop first element of tasks
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

## Getting started
The idea is to [**include** Hypertension in the domain module](#api "Jump to API section"), define the methods and primitive operators, and use this domain module for different problems.
Problems may be in a separate file or generated during run-time.
Since Hypertension uses **metaprogramming**, there is a need to specify which Ruby methods may be used by the [planner](#algorithm "Jump to Algorithm section").
This specification declares operator visibility and the subtasks of each method in the domain structure.

### Example
There is nothing better than an example to understand the behavior of something.
We will start with the [Rescue Robot Robby domain](examples/robby "Robby folder").
Our rescue robot Robby is called to action, the robot is inside an office building trying to check the status of certain locations.
Those locations are defined by the existence of a beacon, and the robot must be in the same hallway or room to check the status.
Robby has a small set of actions available:
- **Enter** a room connected to the current hallway
- **Exit** the current room to a connected hallway
- **Move** from hallway to hallway
- **Report** status of beacon in the current room or hallway

This is the set of primitive operators, not enough to HTN planning.
We need to connect them to the hierarchy.
We know Robby must move, enter and exit zero or more times to reach any beacon, report the beacon, and repeat this process for every beacon.
The result is quite similar to the following regular expression:

```Ruby
/((move|enter|exit)*report)*/
```

We need to match the movement pattern first, the trick part is to avoid repetitions or our robot may be stuck in a loop of A to B and B to A during [search](examples/search/search.jshop).
Robby needs to remember which locations were visited, let us see this in a recursive format.
The base of the recursion happens when the object (Robby) is already at the destination, otherwise use move, enter or exit, mark the position and call the recursion again.
We need to remember to unvisit the locations once we reach our goal to be able to reuse them.

### Domain
We start defininig all the nodes in the hierarchy.
Until now we have the basic operators, visit, unvisit and one method to swap positions defined by the **at** predicate:

```Ruby
require '../../Hypertension'

module Robby
  include Hypertension
  extend self

  @domain = {
    # Operators
    'enter' => true,
    'exit' => true,
    'move' => true,
    'report' => true,
    'visit_at' => false,
    'unvisit_at' => false,
    # Methods
    'swap_at' => [
      'swap_at__base',
      'swap_at__recursion_enter',
      'swap_at__recursion_exit',
      'swap_at__recursion_move'
    ]
  }
end
```

The operators are the same as before, but visit and unvisit are not really important outside the planning stage, therefore they are not visible (``false``), while the others are visible (``true``).
Our movement method ``swap_at`` is there, without any code describing its behavior, only the available methods.
You could compare this with a C header file holding function prototypes.
Each method ``swap_at__XYZ`` describe one possible case of decomposition of ``swap_at``
It is also possible to avoid listing all of them and filter based on their name (after they were declared):
```Ruby
@domain['swap_at'] = instance_methods.find_all {|method| method =~ /^swap_at/}
```

The enter operator appears to be a good starting point, we need to define our preconditions and effects.
I prefer to handle operators with tables, easier to see what is changing:

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
      ['robot', bot],
      ['hallway', source],
      ['room', destination],
      ['at', bot, source],
      ['connected', source, destination]
    ],
    # Negative preconditions
    [
      ['at', bot, destination]
    ],
    # Add effects
    [
      ['at', bot, destination]
    ],
    # Del effects
    [
      ['at', bot, source]
    ]
  )
end
```

The application of an operator creates a new state if the preconditions are satisfied, which requires a deep copy of the state (a costly operation).
You can avoid ``apply_operator`` and handle your own states.
And if you want to create dummy operators to simulate a success or failure without modifications in the state you just return ``true`` or ``false``.
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
end
```

The other operators are no different, time to see how our ``swap_at`` method works.
We need to define every single case as a different method.
The order they appear in the domain definition implies the order of evaluation.
Methods may appear in 3 different scenarios:
- **No preconditions**, direct application of subtasks.
- **Ground preconditions**, apply subtasks if satisfied, every term is a [ground term](http://en.wikipedia.org/wiki/Ground_expression).
- **Lifted preconditions**, unify [free variables](http://en.wikipedia.org/wiki/Free_variables_and_bound_variables) according to the preconditions. [Check how it works](#free-variables).

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
      ['jump', object]
    ]
  end
end
```

#### Ground preconditions
Sometimes we have preconditions in the last operator of the subtask list, we want to discover if the precondition is satisfied now instead of executing a lot of steps to discover this decomposition leads to a failure.
Use preconditions as look-aheads, this may create a redundancy with the operators, but saves quite a lot of time if used wisely.

```Ruby
def swap_at__base(object, goal)
  if applicable?(
    # Positive preconditions
    [
      ['at', object, goal]
    ],
    # Negative preconditions
    []
  )
    yield [
      ['unvisit_at', object]
    ]
  end
end
```

#### Lifted preconditions
It is impossible to propagate variables all the time, some variables must be bound during run-time.
Free variables are created as empty strings, being used as pointers to their future values.
A ``generate([positive], [negative], free_variables)`` method will do the hard work, using positive preconditions to find possible values and unify accordingly, only yielding values that satisfy the preconditions requested.
Therefore a positive precondition set that does not mention all free variables will generate zero unifications.
In classical planning it is possible to try the entire list of objects as values, but in HTN there may be an infinite number of values.
It is possible to solve this problem adding each object possible to be used to the initial state, ``(object kiwi) (object banjo)``, in the initial state and add them in the preconditions, ``(object ?x)``.
Unifications only happen to methods in Hypertension, a method must be created to bound values for an operator if a free variable value is not know.
The following example goes beyond this specification, using an instance variable to avoid cached positions created by other decomposition paths.
You can always use ``if-else`` constructs to speed-up problem solving.
Here it is clear that no state memory is created by Hypertension, that is why we use ``@visited_at``.
This memory is also cleared during the process to reuse previous positions, give a look at visit and unvisit operators in Robby to understand.
You could also define visit and unvisit as predicates, but then your memory would only hold the current path, which makes planning slower.

```Ruby
def swap_at__recursion_enter(object, goal)
  # Free variables
  current = ''
  intermediate = ''
  # Generate unifications
  generate(
    # Positive preconditions
    [
      ['at', object, current],
      ['connected', current, intermediate]
    ],
    # Negative preconditions
    [
      ['at', object, goal]
    ], current, intermediate
  ) {
    unless @visited_at[object].include?(intermediate)
      yield [
        ['enter', object, current, intermediate],
        ['visit_at', object, current],
        ['swap_at', object, goal]
      ]
    end
  }
end
```

#### Free Variables?
Free variables are not supported by Ruby, we need to create them.
A free variable works like a placeholder, once bound it will have a value like any common variable.
The binding process requires the context to dictate possible values to the variable.
In Ruby we can replace the content of a string to a bound value, but that requires the creation of the original string with any value to be used as a pointer, or a more complex solution involving ``method_missing`` to tell the interpreter to create variables if none is found.
I opted for empty strings as free variables, ``my_var = ''``.
If you find this style misleading, add this little method for verbosity reasons with a minimal overhead due to the method call.

```Ruby
def free_variable
  ''
end

my_var = free_variable
```

Free variables can also be defined as arguments, no problem.
You need to define which free variables being used by generate, this avoids the step of searching on every precondition which variables are empty and let you use empty strings as objects if needed.
The example refactored looks like this:

```Ruby
def swap_at__recursion_enter(object, goal, current = free_variable, intermediate = free_variable)
  # Generate unifications
  generate(
    # Positive preconditions
    [
      ['at', object, current],
      ['connected', current, intermediate]
    ],
    # Negative preconditions
    [
      ['at', object, goal]
    ], current, intermediate
  ) {
    block_removed
  }
end
```

### Problem
With the domain ready all you need is to define the initial state and the task list.
The initial state is defined as a Hash table in which the keys are the predicates while the value is an array of possible terms.
The task list follows the same principle, an array of each task to be solved.
Note that the names must match the ones defined in the domain and tasks will be decomposed in the same order they are described (in ordered mode).
Even predicates that do not appear in the initial state must be declared, as ``reported => []`` is declared in the example.
If your problem does not generate objects during run-time a speed improvement can be obtained moving them to variables, therefore the comparisons will be pointer-based.
An interesting idea is to have debug being activated by a command line argument, in this case ``ruby pb1.rb debug`` activates debug mode.

```Ruby
require './Robby'

# Objects
robby = 'robby'
left = 'left'
middle = 'middle'
right = 'right'
room1 = 'room1'
beacon1 = 'beacon1'

Robby.problem(
  # Start
  {
    'at' => [ [robby, left] ],
    'in' => [ [beacon1, room1] ],
    'connected' => [
      [middle, room1],  [room1, middle],
      [left, middle],   [middle, left],
      [middle, right],  [right, middle]
    ],
    'robot' => [ [robby] ],
    'object'=> [ [robby], [beacon1] ],
    'location' => [ [left], [middle], [right], [room1] ],
    'hallway' => [ [left], [middle], [right] ],
    'room' => [ [room1] ],
    'beacon' => [ [beacon1] ],
    'reported' => []
  },
  # Tasks
  [
    ['swap_at', robby, room1],
    ['report', robby, room1, beacon1],
    ['swap_at', robby, right]
  ],
  # Debug
  ARGV.first == 'debug'
)
```

## Hints
Here are some hints to describe your domain:
- Having the objects in variables being reused is faster to compare (pointer comparison), instead of ``String == String``, only works for constant objects.
- Order the methods decomposition wisely, otherwise you may test a lot before actually going to the correct path.
- Use preconditions at your favor, you do not need to test things twice using a smart method decomposition.
- Unification is costly, avoid generate, match your values once and propagate them.
- Even if a precondition or effect is an empty set you need to declare it, use ``[]``.
- Empty predicate sets must be put in the initial state at the problem file. This avoids predicate typos, as all predicates must be previously defined. Or you can use ``Hash.new {|h,k| h[k] = []}`` to create sets at run-time.
- Check out [And-or Trees](http://en.wikipedia.org/wiki/And%E2%80%93or_tree). Which decisions must be made before paths fork and which actions must be done in sequence?
- Using Symbols or constant frozen strings can speed-up things a little, avoiding repeated strings in memory, this was used in the [N Queens example](examples/n_queens/N_Queens.rb "N Queens").
- You can explore further using ``Hash.compare_by_identity`` on domain and state in ``RUBY_VERSION >= 1.9``.

## Execution
The problem acts as the main function since the problems include the domain, and the domain include the planner.
Here we execute the problem 1 of Robby.

```Shell
cd HyperTensioN
ruby examples/robby/pb1.rb
```

If you described your domain and problem in another language you must convert it to Ruby before execution.
Hype can do it for you, it requires a domain and a problem file to be compiled to a certain output type.
The output can be ``print``, ``rb``, ``pddl``, ``jshop``, ``dot``, ``md``, ``run``, ``debug`` or ``nil``.
If no output type is provided the system uses ``print`` as the default, it only prints out what was parsed from the files and the time taken.

```Shell
cd HyperTensioN
# ruby Hype.rb path/domain_filename path/problem_filename {extensions} [output]
# Multiple extensions can be executed before the output happens, more on that to come.
ruby Hype.rb examples/basic/basic.jshop examples/basic/pb1.jshop rb
ruby examples/basic/pb1.jshop.rb
```

You can also compile and execute in a single command with ``run``, the system compile as ``rb`` and require the generated files.
Activate debug mode with ``debug`` to pass the debug flag to the problem and show explored paths instead of only the planning result.

```Shell
ruby Hype.rb examples/basic/basic.jshop examples/basic/pb1.jshop run
ruby Hype.rb examples/basic/basic.jshop examples/basic/pb1.jshop debug
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

Hypertension.state = {...}
Hypertension.applicable?(...)
```
```Ruby
# Mix in
require './Hypertension'

class Foo < Bar
  include Hypertension

  def method(...)
    @state = {...}
    applicable?(...)
  end
end
```

Having the state and domain as separate variables also means there is no need to propagate them.
This also means you can, at any point, change more than the state.
This may be useful to reorder method decompositions in the domain to modify the behavior without touching the methods or set the debug option only after an specific operator is called.
You will notice that the plan is not a variable, as it is created during the backtracking, which means you cannot reorder actions in the planning process using this algorithm, but it is possible with a variation of this algorithm that creates the plan during decomposition.

The methods are few and simple to use:
- ``planning(tasks, level = 0)`` receives a task list, ``[['task1', 'term1', 'term2'], ['task2', 'term3']]``, to decompose and the nesting level to help debug.
Only call this method after domain and state were defined.
This method is called recursively until it finds an empty task list, ``[]``, then it starts to build the plan while backtracking to save CPU (avoid intermediate plan creation).
Therefore no plan actually exists before reaching an empty task list.
In case of failure, ``nil`` is returned.

- ``applicable?(precond_pos, precond_not)`` tests if the current state have all positive preconditions and not a single negative precondition. Returns ``true`` if applicable, ``false`` otherwise.
- ``apply(effect_add, effect_del)`` modifies the current state, add or remove predicates present in the lists. Returns true.
- ``apply_operator(precond_pos, precond_not, effect_add, effect_del)`` extends this idea applying effects if ``applicable?``. Returns ``true`` if applied, ``nil`` otherwise.
- ``generate(precond_pos, precond_not, *free)`` yields all possible unifications to the free variables defined, therefore you need a block to capture the unifications. The return value is undefined.
- ``print_data(data)`` can be used to print task and predicate lists, useful for debug.
- ``problem(start, tasks, debug = false, goal_pos = [], goal_not = [])`` is used to simplify the setup of a problem instance, returns the value of planning. Use problem as a template to see how to add Hypertension in your project.
- ``task_permutations(state, tasks, goal_pos, goal_not)`` tries several task permutations to achieve unordered decomposition, it is used by ``problem`` when explicit goals are given. Returns a plan or ``nil``.

Domain operators can be defined without ``apply_operator`` and will have the return value considered.
  - ``false`` or ``nil`` means the operator has failed.
  - Any other value means the operator was applied with success.

Domain methods must yield a task list or are nullified, having no decomposition.

## Hype
[**Hype**](Hype.rb) is the framework for parsers and compilers of planning descriptions.
It will save time and avoid errors during conversion of domains and problems for comparison results with other planners.
Such conversion step is not uncommon, as JSHOP2 itself compiles the description to Java code, trying to achieve the best performance possible.

**Parser support**:
- [Ruby](https://en.wikipedia.org/wiki/Ruby_%28programming_language%29) using an [Intermediate Representation](docs/Representation.md)
- [PDDL](http://en.wikipedia.org/wiki/Planning_Domain_Definition_Language "PDDL at Wikipedia")
- [JSHOP]

**Compiler support**:
- Hypertension (methods and tasks may not be available if the input was PDDL)
- [PDDL](http://en.wikipedia.org/wiki/Planning_Domain_Definition_Language "PDDL at Wikipedia") (methods are ignored, goal must be manually converted based on tasks)
- [JSHOP] (methods and tasks may not be available if the input was PDDL)
- [Graphviz DOT](http://www.graphviz.org/) (generate a [graph](docs/Graph.md) description to be compiled into an image)
- [Markdown](http://daringfireball.net/projects/markdown/)

As any parser, the ones provided by Hype are limited in one way or another.
[PDDL](http://en.wikipedia.org/wiki/Planning_Domain_Definition_Language "PDDL at Wikipedia") have far more features than supported by most planners and [JSHOP] have 2 different ways to define methods.
Methods may be broken into several independent blocks or in the same block without the need to check the same preconditions again.
Both cases are supported, but we evaluate the preconditions of each set independently while [JSHOP] only evaluates the last if the first ones evaluated to false in the same block.
In order to copy the behavior we cannot simply copy the positive preconditions in the negative set and vice-versa.
Sometimes only one predicate in the set is false, if we copied in the other set for the other methods it would never work.
It is possible to declare the methods in the same Ruby method (losing label definition), but kills the simplicity we are trying to achieve.
We also do not support [JSHOP] axioms and external calls, yet.

You can always not believe the **Hype** and convert descriptions manually, following a style that achieves a better or faster solution with the indentation that makes you happy.
You could add counters in the methods and return after generate unified one or more times a specific value.
It is possible to support [JSHOP] behavior putting several generators in one method and returning if the previous one ever unified.
Well, Hype can do most of the boring stuff so you can play with the details.

### Parsers
Parsers are modules that read planning descriptions and convert the information to an [Intermediate Representation](docs/Representation.md).
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

With the parser completed we need to connect with the Hype based on the file extensions of the files provided.
It is expected that domain and problem files have the same extension to avoid incomplete data from mixed inputs.
The parser is responsible for file reading.
This allows uncommon, but possible, binary files.

### Compilers
Compilers are modules that write planning descriptions based on the information available in the [Intermediate Representation](docs/Representation.md) format.
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

Unlike parsers, compilers have a choice in their output.
The first option is for uncommon outputs, they must be handled inside the methods and return ``nil``.
The second option is to output a more common text file and return the string to be written.
If the second option was selected the output filename is the input filename with the new extension appended, therefore ``input.pddl`` to ``jshop`` would be ``input.pddl.jshop``, so no information about the source is lost.
Any compiler have access to the parser attributes, which means one module can optimize before another compiles.
In fact this is the core idea behind Hype, be able to parse, modify and compile domains without having to worry about language support.
Future languages compatible with the [Intermediate Representation](docs/Representation.md) format could be supported by just adding a new parser and compiler.
The compiler is expected to not modify any parameter, use an extension to achieve such result.

### Extensions
Extensions are modules that transform planning descriptions.
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
Since they transform existing structures any value returned is ignored.

## Comparison
The main advantage is to be able to define behavior in the core language, without losing clarity, this alone gives a lot of power.
JSHOP2 requires the user to dive into a very complex structure to unlock such power.
[Pyhop] is based on this feature, everything defined in Python, but does not support backtracking and unification, which means the user have to create its own unification system and a domain that does not require backtracking.
The biggest advantage is not the planner itself, but the parsers and compilers built around it, so that descriptions can be converted automatically.
Perhaps the most invisible advantage is the lack of custom classes, every object used during planning is defined as one of the core objects.
Once Strings, Arrays and Hashes are understood, the entire Hypertension module is just a few methods away from complete understanding.

Among the lacking features is interleaved/unordered execution of tasks, a feature that JSHOP2 supports and is extremely important to achieve good plans in some cases, and lazy variable evaluation.
We only support unordered tasks at the problem level and do not interleave them during decomposition.
Since we test for explicit goals only after the plan has been found with a sequence of tasks, a failure is considered enough proof to try other orderings, not other unifications with the same sequence of tasks.

## Changelog
- Mar 2014
  - Converted Pyhop to Ruby
  - Data structures modified
- Jun 2014
  - converted ND_Pyhop to Ruby
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
  - Released version 1.0 as last version supporting Ruby 1.8

## ToDo's
- Order predicates and test applicability by level (generate)
- Unordered subtasks
- Anytime mode
- Debugger (why is the planner not returning the expected plan?)
- More tests

[JSHOP]: http://www.cs.umd.edu/projects/shop/description.html "SHOP/JSHOP project page"
[Pyhop]: https://bitbucket.org/dananau/pyhop "Pyhop project page"