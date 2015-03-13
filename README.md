# HyperTensioN
HTN planning in Ruby

Hypertension is an Hierarchical Task Network Planner written in Ruby, which means you have to describe how tasks can be accomplished using method decomposition to achieve a plan. This is very alike to how humans think, taking mental steps further into primitive operators. When all operators in the plan are satisfied, the plan found is a valid one.

The current version has most of its algorithm inspired by PyHop, with backtracking and unification added.

## Algorithm

The algorithm for HTN planning is quite simple and flexible, the hard part is in the structure that decomposes and the unification engine. Our task list (input of planning) is decomposed until nothing remains, the base of recursion, returning an empty plan. The tail of recursion are the operator and method cases. The operator tests if the current task (the first in the list, since it decomposes in order here) can be applied to the current state (which is a visible structure to the other Ruby methods, but does not appear here). If successfully applied, the planning continues decomposing and insert the current task in the beginning of the plan, as it builds the plan during recursion from last to first. If it is a method, the path is different, we need to decompose into one of several cases with a valid unification for the free-variables. Each case unified is a list of tasks, subtasks, that may require decomposition too, occupying the same place the method that generated them once was. I exposed the unification only to methods, but it is possible to expose to operators too (which kinda kills the idea of what a primitive is to me). This way the methods take care of the heavy part (should the _agent_ **move** from _here_ to _there_ by **foot**[walking] or call a **cab**[call,enter,ride,pay,exit]) while the primite operators just execute the effects when applicable. If no decomposition happens, failure is returned.

```
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

The idea is to **include** Hypertension in your domain module, define the methods and primitive operators, and use this domain module with your different problems for this domain. Your problems may be in a separate file or be generated during run-time. Since Hypertension uses **metaprogramming**, you need to specify which Ruby methods are used and how. The other way to define this would be the unit test way, using certain method names as type filters.
I chose the explicit way, therefore you need to specify operator visibility and the subtasks of each method by hand.

### Example

Nothing better than an example to understand the behavior of something. We will start with the **Robby domain**. Our rescue robot Robby is called to action, the robot is inside an office building trying to check the status of certain locations. Those locations are defined by the existence of a beacon, and the robot must be in the same hallway or room to check the status. Robby has a small set of actions available:
- **Enter** a room connected to the current hallway
- **Exit** the current room to a connected hallway
- **Move** from hallway to hallway
- **Report** status of beacon in the current room or hallway

This is the set of primitive operators, not enough to HTN planning. We need to expand it. We know Robby must move, enter and exit zero or more times to reach any beacon, report the beacon, and repeat this process for every beacon.
If you are used to regular expressions the result is similar to this:
```Ruby
/((move|enter|exit)*report)*/
```

We need to match the movement pattern first, the trick part is to avoid repetitions or our robot may be stuck in a loop of A to B and B to A again. Robby needs to remember which locations were visited, let us see this in a recursive format. The movement actions swap the position of Robby, predicate ```at```. The base of the recursion happens when the object (Robby) is already at the destination, otherwise use move, enter or exit, mark the position and call the recursion again. We need to remember to unvisit the locations once we reach our goal, otherwise Robby may be stuck:

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

This example is hardcoded and abstracts most of the problem, it is time to build it in HTN. Remember to exploit the recursive nature of HTN to take the decisions for you, this make it simpler.

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

The operators are the same as before, but visit and unvisit are not really important outside the planning stage, therefore they are not visible (```false```), while the others are visible (```true```). Our swap_at method is there, without any code describing its behavior. You could compare this with the header file holding the prototypes of functions as in C. And yes, I did not created the outerside pattern ```/(?:swap_at*report)*/```, one step at a time.

The enter operator appears to be a good starting point, we need to define our preconditions and effects. I prefer to handle them in a table, easier to see what is changing:

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

The other operators are no different, time to see how our swap_at method works. We need to define every single case as a different method. The order they appear in the domain definition implies the order of evaluation. Methods may appear in 3 different scenarios:
- **No preconditions**, direct application of subtasks.
- **Grounded preconditions**, apply subtasks if satisfied, every variable is [grounded](http://en.wikipedia.org/wiki/Ground_expression).
- **Lifted preconditions**, unify [free-variables](http://en.wikipedia.org/wiki/Free_variables_and_bound_variables) according to the preconditions.

Instead of returning, the methods yield a subtask list. This approach solves the problem of returning several unifications per method call, yielding them as required. Be aware that all methods must have the same parameter list, other variables must be bounded during run-time (**Lifted preconditions**).

#### No preconditions

This is the simplest case, the method **yields** a subtask list without test. The list may be empty. This example is not part of the current implementation of Robby.

```Ruby
def swap_at__jump(object, goal)
    yield [
      ['jump', object]
    ]
  end
end
```

#### Grounded preconditions

Sometimes we have preconditions in the last operator of the subtask list, we want to discover if the precondition is satisfied now instead of executing a lot of steps to discover this decomposition leads to a failure. Use preconditions as look-aheads, this may create a redundancy with the operators, but saves quite a lot of time if used wisely.

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

It is impossible to propagate variables all the time, some variables must be bounded during run-time. Free-variables are created as empty strings, being used as pointers to their future values. A ```generate([true],[false],free-variables)``` method will do the hard job, using positive preconditions to find possible values and unify accordingly, only yielding values that satisfy the preconditions requested. The following example goes beyond this specification, using an instance variable to avoid cached positions created by other decomposition paths. You can always use ```if-else``` constructs to speed-up problem solving. Here it is clear that no state memory is created by Hypertension, that is why we use ```@visited_at```. This memory is also cleared during the process to reuse previous positions, give a look at visit and unvisit operators in Robby to understand. You could also define visit and unvisit as predicates, but then your memory would only hold the current path, which makes it slower.

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

### Problem

ToDo PUT ROBBY EXAMPLE HERE

## Execution

The problem acts as the main function since the problems include the domain, and the domain include the planning engine.

```
cd HyperTensioN/examples/project
ruby pb1.rb
```

The parsing engine is still under development and eventually will be able to read both PDDL operators and JSHOP methods and operator, and convert to Hypertension code. This is not uncommon, as JSHOP itself compiling methods and operators to Java, trying to achieve the best performance possible. Currently JSHOP is the only language being supported. If no output folder is provided the system prints out what was understood from the files.

```
ruby Hyparser.rb domain_file problem_file [output_folder]
```

## API

ToDo

## Advantages

ToDo

## ToDoS
- Complete the README
