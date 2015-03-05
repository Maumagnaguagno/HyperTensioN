# HyperTensioN
HTN planning in Ruby

Hypertension is an Hierarchical Task Network Planner written in Ruby, which means you have to describe how tasks can be accomplished using method decomposition to achieve a plan. This is very alike to how humans think, taking mental steps further into primitive operators. When all operators in the plan are satisfied, the plan found is a valid one.

The current version has most of its algorithm inspired by PyHop, with backtracking and unification added.

# Algorithm

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

# How it works

The idea is to **include** Hypertension in your domain module, define the methods and primitive operators, and use this domain module with your different problems for this domain. Your problems may be in a separate file or be generated during run-time. Since Hypertension uses **metaprogramming**, you need to specify which Ruby methods are used and how. The other way to define this would be the unit test way, using certain method names as type filters.
I chose the explicit way, therefore you need to specify operator visibility and the subtasks of each method by hand.

## Example

ToDo description

### Domain example

ToDo PUT ROBBY EXAMPLE HERE

### Problem

ToDo PUT ROBBY EXAMPLE HERE

## Advantages

ToDo

# ToDoS
- Complete the README
