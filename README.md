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
- Enter a room connected to the current hallway
- Exit the current room to a connected hallway
- Move from hallway to hallway
- Report status of beacon in the current room or hallway

This is the set of primitive operators, not enough to HTN planning. We need to expand it. We know Robby must move, enter and exit zero or more times to reach any beacon, report the beacon, and repeat this process for every beacon.
If you are used to regular expressions the result is similar to this (using ```,``` as a separator):
```Ruby
/(?:(?:move,|enter,|exit,)*report,)*/
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

The other operators are no different, time to see how our swap_at method works:

ToDo

### Problem

ToDo PUT ROBBY EXAMPLE HERE

## API

ToDo

## Advantages

ToDo

## ToDoS
- Complete the README
