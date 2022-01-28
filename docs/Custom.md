# Custom Domain
Domains with unique details/optimizations that cannot be represented by any of the input formalisms accepted by [Hype](../README.md#hype "Jump to Hype") require custom descriptions only possible in the core language, Ruby.
Note that custom domains cannot be further optimized/verified by static analysis extensions for each instance and may be harder to maintain and port.
Two examples are available: [N-Queens](../examples/n_queens/N_Queens.rb) and [Sudoku](../examples/sudoku/Sudoku.rb).

A module represents the domain according to the [API](../README.md#api "Jump to API"), define the methods and primitive operators, and reused for different problems.
Problems may be in a separate file or generated during run-time.
Since HyperTensioN uses **metaprogramming**, there is a need to specify which Ruby methods may be used by the [planner](../README.md#algorithm "Jump to Algorithm").
This specification declares operator visibility and the subtasks of each method in the domain structure.

### Example
Here the [Rescue Robot Robby domain](../examples/robby "Robby folder") is used as a domain example.
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

Easier to start with the movement operators, the tricky part is to avoid repetitions or the robot may be stuck in a loop of A to B and B to A during [search](../examples/search/search.jshop).
Robby needs to remember which locations were visited using a recursive description.
The base of the recursion happens when the object (Robby) is already at the destination, otherwise use move, enter or exit, mark the position and call the recursion again.
Locations must be unvisited once the destination is reached to be able to reuse such locations.

### Domain
The first step is to define all the nodes in the hierarchy.
Nodes include the basic operators, visit, unvisit and one method to swap positions defined by the **at** predicate:

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
Each ``swap_at__XYZ`` method describes one possible case of decomposition of ``swap_at``.
It is also possible to avoid listing all of them and filter based on their name (after they were declared):

```Ruby
@domain[:swap_at] = instance_methods.grep(/^swap_at/)
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

The other operators are no different, time to see how ``swap_at`` methods work.
Every case is defined as a different method.
The order they appear in the domain definition implies the order of evaluation.
Methods may appear in 3 different scenarios:
- **No preconditions**, direct application of subtasks.
- **Ground preconditions**, apply subtasks if satisfied, every term is a [ground term](https://en.wikipedia.org/wiki/Ground_expression).
- **Lifted preconditions**, unify [free variables](https://en.wikipedia.org/wiki/Free_variables_and_bound_variables) according to the preconditions.

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
```

#### Ground preconditions
Sometimes unique preconditions appear in the last operator of the subtask list.
One wants to know if such preconditions are satisfied before the execution of several steps to discover if this decomposition leads to a failure.
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
It is possible to solve this problem adding each object possible to be used to the initial state, ``(object kiwi) (object banjo)``, in the initial state and add them in the preconditions, ``(object var)``.
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
    ...
  }
end
```

The compilers use a less readable but optimized approach without generate and free variables.
Static analysis is able to determine that ``connected`` is a rigid predicate, never changes, which can be stored in a constant outside the state.
Both ``at`` and ``connected`` predicates are iterated, looking for a suitable set of values that satisfy the original method preconditions.

```Ruby
def swap_at__recursion_enter(_object, _goal)
  return if @state[AT].include?([_object, _goal])
  @state[AT].each {|_object_ground, _current|
    next if _object_ground != _ground
    CONNECTED.each {|_current_ground, _intermediate|
      next if _current_ground != _current
      ...
    }
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