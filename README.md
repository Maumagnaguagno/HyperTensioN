# HyperTensioN
**HTN planning in Ruby**

Hypertension is an Hierarchical Task Network Planner written in Ruby, which means you have to describe how tasks can be accomplished using method decomposition to achieve a plan, but in Ruby.
This is very alike to how humans think, taking mental steps further into primitive operators. When all operators in the plan are satisfied, the plan found is a valid one.
HTN is used as an acronym for Hypertension in medical context, therefore the name was given.

The current version has most of its algorithm inspired by PyHop, with backtracking and unification added.
It is being developed with **Ruby 2.0** in mind, if you find some feature that does not work with your environment you can report an issue.

In order to support other planning languages a module named [Hype](#hype) will take care of the conversion process.

## Algorithm

The algorithm for HTN planning is quite simple and flexible, the hard part is in the structure that decomposes and the unification engine.
Our task list (input of planning) is decomposed until nothing remains, the base of recursion, returning an empty plan.
The tail of recursion are the operator and method cases.
The operator tests if the current task (the first in the list, since it decomposes in order here) can be applied to the current state (which is a visible structure to the other Ruby methods, but does not appear here).
If successfully applied, the planning process continues decomposing and inserting the current task at the beginning of the plan, as it builds the plan during recursion from last to first.
If it is a method, the path is different, we need to decompose into one of several cases with a valid unification for the free-variables.
Each case unified is a list of tasks, subtasks, that may require decomposition too, occupying the same place the method that generated them once was.
I exposed the unification only to methods, but it is possible to expose to operators too (which kills the idea of what a primitive is).
Now the methods take care of the heavy part (should the _agent_ **move** from _here_ to _there_ by **foot** ```[walking]``` or call a **cab** ```[call, enter, ride, pay, exit]```) while the primitive operators just execute the effects when applicable.
If no decomposition happens, failure is returned.

```Ruby
Algorithm planning(list tasks)
  return empty plan if tasks = empty
  current_task <- pop first element of tasks
  if current_task is an Operator
    if apply_operator(current_task)
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

## How it works

The idea is to **include** Hypertension in your domain module, define the methods and primitive operators, and use this domain module with your different problems for this domain.
Your problems may be in a separate file or be generated during run-time.
Since Hypertension uses **metaprogramming**, you need to specify which Ruby methods are used and how.
The other way to define this would be the unit test way, using certain method names as type filters.
I chose the explicit way, therefore you need to specify operator visibility and the subtasks of each method by hand.

### Example

There is nothing better than an example to understand the behavior of something.
We will start with the **Robby domain**.
Our rescue robot Robby is called to action, the robot is inside an office building trying to check the status of certain locations.
Those locations are defined by the existence of a beacon, and the robot must be in the same hallway or room to check the status.
Robby has a small set of actions available:
- **Enter** a room connected to the current hallway
- **Exit** the current room to a connected hallway
- **Move** from hallway to hallway
- **Report** status of beacon in the current room or hallway

This is the set of primitive operators, not enough to HTN planning.
We need to expand it.
We know Robby must move, enter and exit zero or more times to reach any beacon, report the beacon, and repeat this process for every beacon.
If you are used to regular expressions the result is similar to this:
```Ruby
/((move|enter|exit)*report)*/
```

We need to match the movement pattern first, the trick part is to avoid repetitions or our robot may be stuck in a loop of A to B and B to A again.
Robby needs to remember which locations were visited, let us see this in a recursive format.
The movement actions swap the position of Robby, predicate ```at```.
The base of the recursion happens when the object (Robby) is already at the destination, otherwise use move, enter or exit, mark the position and call the recursion again.
We need to remember to unvisit the locations once we reach our goal, otherwise Robby may be stuck. The following code illustrates the idea without HTN:

```Ruby
def swap_at(object, goal)
  if swap_at__base(object, goal)
    return []
    unvisit(object)
  elsif swap_at__enter(object, goal)
    visited(object.position)
    return [enter] + swap_at(object, goal)
  elsif swap_at__recursion_exit(object, goal)
    visited(object.position)
    return [exit] + swap_at(object, goal)
  elsif swap_at__recursion_move(object, goal)
    visited(object.position)
    return [move] + swap_at(object, goal)
  end
end
```

This example is hardcoded and abstracts most of the problem, it is time to build it in HTN.
Remember to exploit the recursive nature of HTN to take the decisions for you, this will make it simpler.

### Domain example

Better start with code:

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

The operators are the same as before, but visit and unvisit are not really important outside the planning stage, therefore they are not visible (```false```), while the others are visible (```true```).
Our swap_at method is there, without any code describing its behavior.
You could compare this with the header file holding the prototypes of functions as in C.
And yes, I did not created the outerside pattern ```/((swap_at)*report)*/```, one step at a time.

The enter operator appears to be a good starting point, we need to define our preconditions and effects.
I prefer to handle them in a table, easier to see what is changing:

**enter(bot, source, destination)**

| Preconditions | Effects |
| ---: | ---: |
| robot(bot) | |
| hallway(source) ||
| room(destination) ||
| connected(source, destination) ||
| at(bot, source) | **not** at(bot, source) |
| **not** at(bot, source) | at(bot, destination) |

This translates to:

```Ruby
def enter(bot, source, destination)
  apply_operator(
    # True preconditions
    [
      ['robot', bot],
      ['hallway', source],
      ['room', destination],
      ['at', bot, source],
      ['connected', source, destination]
    ],
    # False preconditions
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

And if you want to create dummy operators to simulate a success or failure without modifications in the current state you just return the outcome.
Success may be useful during the debug process or to change an internal feature of the agent wrapping the HTN when parsing the plan returned.
Failure can be used to destroy the current plan decomposition without the use of preconditions, a specific case in which this construct is useful is not know.

```Ruby
def success(term1, term2)
  true
end

def failure(term1, term2)
  false
end
```

The other operators are no different, time to see how our swap_at method works.
We need to define every single case as a different method.
The order they appear in the domain definition implies the order of evaluation.
Methods may appear in 3 different scenarios:
- **No preconditions**, direct application of subtasks.
- **Grounded preconditions**, apply subtasks if satisfied, every variable is [grounded](http://en.wikipedia.org/wiki/Ground_expression).
- **Lifted preconditions**, unify [free-variables](http://en.wikipedia.org/wiki/Free_variables_and_bound_variables) according to the preconditions. [See how it works](#free-variables).

Instead of returning, the methods yield a subtask list.
This approach solves the problem of returning several unifications per method call, yielding them as required.
Be aware that all methods must have the same parameter list, other variables must be bounded during run-time (**Lifted preconditions**).

#### No preconditions

This is the simplest case, the method **yields** a subtask list without any test.
The subtask list may be empty.
This example is not part of the current implementation of Robby.

```Ruby
def swap_at__jump(object, goal)
    yield [
      ['jump', object]
    ]
  end
end
```

#### Grounded preconditions

Sometimes we have preconditions in the last operator of the subtask list, we want to discover if the precondition is satisfied now instead of executing a lot of steps to discover this decomposition leads to a failure.
Use preconditions as look-aheads, this may create a redundancy with the operators, but saves quite a lot of time if used wisely.

```Ruby
def swap_at__base(object, goal)
  if applicable?(
    # True preconditions
    [
      ['at', object, goal]
    ],
    # False preconditions
    []
  )
    yield [
      ['unvisit_at', object]
    ]
  end
end
```

#### Lifted preconditions

It is impossible to propagate variables all the time, some variables must be bounded during run-time.
Free-variables are created as empty strings, being used as pointers to their future values.
A ```generate([positive],[negative],free-variables)``` method will do the hard job, using positive preconditions to find possible values and unify accordingly, only yielding values that satisfy the preconditions requested.
The following example goes beyond this specification, using an instance variable to avoid cached positions created by other decomposition paths.
You can always use ```if-else``` constructs to speed-up problem solving.
Here it is clear that no state memory is created by Hypertension, that is why we use ```@visited_at```.
This memory is also cleared during the process to reuse previous positions, give a look at visit and unvisit operators in Robby to understand.
You could also define visit and unvisit as predicates, but then your memory would only hold the current path, which makes planning slower.

```Ruby
def swap_at__recursion_enter(object, goal)
  # Free variables
  current = ''
  intermediary = ''
  # Generate unifications
  generate(
    # True preconditions
    [
      ['at', object, current],
      ['connected', current, intermediary]
    ],
    # False preconditions
    [
      ['at', object, goal]
    ], current, intermediary
  ) {
    unless @visited_at[object].include?(intermediary)
      yield [
        ['enter', object, current, intermediary],
        ['visit_at', object, current],
        ['swap_at', object, goal]
      ]
    end
  }
end
```

#### Free Variables?

Free variables are not supported by Ruby, we need to simulate their behavior.
A free variable works like a placeholder, once bounded it will have a value like any common variable.
The bounding process requires the context to dictate possible values to the variable.
In Ruby we can replace the content of a string to the bounded value, but that requires the creation of the original string with any value or a more complex solution involving ```method_missing``` to tell the interpreter to create variables if none is found.
If you find my style a little misleading, ```my_var = ''```, you can add this little method for verbosity reasons with a minimal overhead due to the method call.

```Ruby
def free_variable
  ''
end
```

You can also define the free variables as arguments, no problem.
You still need to pass to generate the free variables being used, this avoids the step of searching on every element of the preconditions which variables are empty and let you use empty strings as objects if needed.
The only way to create seamless free variables is to rescue inside a block, which is a slow alternative.
The example refactored looks like this:

```Ruby
def swap_at__recursion_enter(object, goal, current = free_variable, intermediary = free_variable)
  # Generate unifications
  generate(
    # True preconditions
    [
      ['at', object, current],
      ['connected', current, intermediary]
    ],
    # False preconditions
    [
      ['at', object, goal]
    ], current, intermediary
  ) {
    block_removed
  }
end
```

### Problem

With your domain ready all you need is to define the initial state and the task list.
The initial state is defined as a Hash table in which the keys are the predicates while the value is an array of possible terms.
The task list follows the same principle, an array of each task to be solved.
Note that the names must match the ones defined in the domain and tasks will be decomposed in the same order they are described.
Even if a predicate has no true terms associated in the initial state you must declare them, as ```reported => []``` is declared in the example.
If your problem does not generate objects during run-time a speed improvement can be obtained moving them to variables, therefore the comparisons will be pointer-based.
An interesting idea is to have debug being activated by a command line argument, in this case ```ruby pb1.rb -d``` activates debug mode.

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
  ARGV.first == '-d'
)
```

## Hints

Here are some hints for everyone:
- Having an a common object in a variable being reused is faster to compare (pointer comparison), instead of String == String, only works for constant objects.
- Order the methods decomposition wisely, otherwise you may test a lot before actually going to the correct path.
- Use the precondition in you favor, you do not need to test things twice using a smart method decomposition.
- Unification is costly, avoid generate at any cost, match your values once and propagate them as long as possible.
- Even if a precondition or effect is an empty set you need to declare it, use ```[]```.
- Empty predicate sets must be put in the initial state at the problem file. This avoids predicate typos, as all predicates must be previously defined.
- Think like an [And-or Tree](http://en.wikipedia.org/wiki/And%E2%80%93or_tree), which decisions must be made before paths fork and which actions must be done in sequence?

## Execution

The problem acts as the main function since the problems include the domain, and the domain include the planner.

```
cd HyperTensioN/examples/project
ruby pb1.rb
```

## API

Here are the descriptions to use and extend Hypertension and Hype functionality.
Hypertension being the module with the planning engine and Hype being a collection of parsers and compilers to generate code from/to several planning formats.

### Planner

Hypertension is a Ruby module and have a few instance variables:
- ```@state``` with the current state.
- ```@domain``` with the decomposition rules that can be applied to the operators and methods.
- ```@debug``` as a flag to print intermediary data during planning.

They were defined as instance variables to be mixed in other classes if needed, that is why they are not class variables.
Having the state and domain as separate variables also means we do not need to propagate them all the time, this makes the source more declarative.
This also means you can, at any point, change more than the state.
This may be usefull to reorder method decompositions in the domain to modify the behavior without touching the methods or set the debug option only after an specific operator is called.
You will notice that the plan is not a variable, as it is created during the backtracking, which means you can not reorder actions in the planning process using this algorithm, but is possible if you create the plan during decomposition and costs more CPU.

The methods are few and simple to use:
- ```planning(tasks, level = 0)``` receives a task list to decompose and the nesting level to help debug.
Only call this method after domain and state definition.
This method is called recursively until it finds an empty task list, then it starts to build the plan in the backtracking.
Therefore no plan actually exists before reaching an empty task list.

  ```Ruby
task_list = [['task1', 'term1', 'term2'], ['task2', 'term3']]
empty_task_list = []
  ```
- ```applicable?(precond_true, precond_false)``` is used to test if all true preconditions are found and no false precondition is present at the current state.
It returns true if applicable and false otherwise.
- ```apply_operator(precond_true, precond_false, effect_add, effect_del)``` extends this idea applying effects if ```applicable?```. Returns true if applied, false otherwise.
- ```generate(precond_true, precond_false, *free)``` yields all possible unifications to the free-variables defined, therefore you need a block to capture the unifications. The return value is undetermined.
- ```print_data(data)``` can be used to print task lists and proposition lists, usefull for debug.
- ```problem(start, tasks, debug = false)``` can be used to simplify the creation of a problem instance. Use it as a template to see how to add Hypertension in your project.

Domain operators can be defined without ```apply_operator``` and will have the return value considered.
  - ```false``` or ```nil``` means the operator has failed.
  - Any other value means the operator was applied with success.

Domain methods must yield a task list or are nullified, having no decomposition.

## Hype

The **Hype** is the framework for parsers and compilers of planning languages and common representations.
It will save time and avoid errors during conversions of domains and problems for comparison results with other planners.
This conversion step is not uncommon, as JSHOP itself compiles the description to Java code, trying to achieve the best performance possible.

**Parser support**:
- [x] [PDDL](http://en.wikipedia.org/wiki/Planning_Domain_Definition_Language)
- [x] [JSHOP](http://www.cs.umd.edu/projects/shop/description.html)
- [ ] [HPDDL](https://github.com/ronwalf/HTN-Translation)

**Compiler support**:
- [x] Hypertension (methods and tasks may not be available if the input was PDDL)
- [x] PDDL (methods are ignored, goal must be manually converted from the tasks)
- [x] JSHOP (methods and tasks may not be available if the input was PDDL)
- [x] [Graphviz DOT](http://www.graphviz.org/) (generate a graph description to be compiled into an image)
- [ ] HPDDL (methods and tasks may not be available if the input was PDDL)

As any parser the ones provided by Hype are limited in one way or another, PDDL have far more features than supported by most planners and JSHOP have 2 different ways to define methods.
Methods may be broken into several independent blocks or in the same block without the need to check the same preconditions again.
We support both cases, but we evaluate the preconditions of each set independently while JSHOP only evaluates the last if the previous ones evaluated to false in the same block.
In order to copy the behavior we can not simply copy the positive preconditions in the negative set and vice-versa.
Sometimes only one proposition in the set is false, if we copied in the other set for the other methods it would never work.
Declare the methods in the same Ruby method is possible (losing label definition), but kills the simplicity and declaration independence we are trying to achieve. We also do not support axioms yet.

You can always not believe the **Hype** and convert descriptions by yourself, following a style that achieves a better or faster solution with the indentation that makes you happy.


## Execution

Hype requires a domain and problem file to be compiled to a certain output type.
If no output type is provided or 'print' is provided, the system only prints out what was understood from the files and the time taken to parse.

```
ruby Hype.rb path/domain_filename path/problem_filename [rb|pddl|jshop|dot|print]
```

### Parsers

Parsers are modules to be used to read planning descriptions, they are being developed now and still require a standard interface.
The prototype interface is a module with the domain attributes and two methods to parse problem and domain files:

```Ruby
module Foo_Parser
  extend self

  attr_reader :domain_name, :problem_name, :problem_domain, :operators, :methods, :predicates, :state, :tasks, :goal_pos, :goal_not

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

With the parser completed you need to connect with the Hype based in the file extensions of the files provided.
Both files (domain and problem) must have the same extension.
Maybe the file reading is common enough to be read outside the parsers, but then no special files would be supported, like:
- Binary files (uncommon, but possible)
- Problem generators (common)

### Compilers

Compilers are modules to be used to write planning descriptions, they are being developed now and still require a standard interface.
The prototype interface is a module with two methods to compile problem and domain files to text:

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

In the same sense of the parsers, it would be a better idea to handle the file here, which is still possible doing what you need and returning nil.
The output filename is the input filename plus the new extension, therefore ```input.pddl``` to jshop would be ```input.pddl.jshop```, so that you do not lose the information about the source.
Note that any compiler have access to the parser attributes, which means you can call one module to optimize before calling another to actually compile.
In fact this is the core idea behind Hype, be able to parse, modify and compile domains without having to worry about language support, any future language could be supported just adding a new parser and compiler.

## Advantages

The main advantage is to be able to define behavior in the core language, if you wish, without losing clarity, this alone gives a lot of power.
JSHOP requires you to dive into a very complex structure if you want to unlock this power.
PyHop is based in this feature, everything is Python, but does not support backtracking and unification, which means you will have to create your own unification system and define your domain so no backtracking is required.
The biggest advantage is not the planning itself, but the parsers and compilers being built around it, so that your description can be converted automatically without breaking compatibility with other planners.
JSHOP and PyHop live in their own world, with their own language acting as a barrier.
Perhaps the most invisible advantage is the lack of classes, every object used during planning is defined as one of the core objects.
Once the designer understands Strings, Arrays and Hashes the entire Hypertension module is just a few methods away from complete understanding.
This also means that any update in the implementation of Ruby will benefit this project directly, as those objects are always target of optimizations.
The only feature that we lack is unordered execution of tasks, a feature that JSHOP supports and is extremely important to achieve good plans in some cases.

## Old Versions

You may notice an [old_versions](old_versions) folder with incompatible variations of Hypertension.
This folder contains the RubyHop (PyHop remade in Ruby) and Simple (Hypertension without unification).
Simple shares the core of Hypertension, but builds the plan while searching, while Hypertension builds the plan after, and support probability planning to show all outcomes that may happen.
I left them in a separate folder as some of their features are now gone.
I plan to create variations of the current core to support the plan built during search and probabilistic outcomes in the future, probably when I need those.
Those versions also let you express your state in any way you want, but you need to take care of eveything, which is not the case now as unification and operator application require a standard structure.
- **RubyHop** is interesting only if you want to port from PyHop.
- **Plan built during search** is useful to interleave tasks and optimize the plan.
- **Probabilistic planning** is useful if you need to know what may happen and the different probabilities of each scenario. It takes much longer to execute, as many branches may happen.

## ToDo's
- Parsers with more features support
- Compilers with more features support
- Define the standard interface for parsers and compilers, the current ones require several attributes instead of a Hash ```{:attr => data}``` and there is an inconsistency about file handling (Hype should do all IO).
- Tests
- Examples
- Maybe ```applicable?(precond_true, precond_false)``` in generate does not need to test precond_true
  - ```applicable?([], precond_false)``` appears to be enough
