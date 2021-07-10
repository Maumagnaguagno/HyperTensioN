# Patterns
Hype is able to extend classical planning instances and generate methods and tasks to solve them with a HTN planner using Patterns and [Dummy](Dummy.md).
Methods are generated using patterns identified in the operators and used to solve common subproblems.
Such patterns are based on predicate usage among the preconditions and effects of the operators.
The patterns are explained in the next sections using PDDL actions and their related pattern-based methods in JSHOP.
Note that only some of the generated methods are displayed here, as complex actions generate more methods with multiple base/goal cases for swap and dependency patterns.
More information is presented in the paper [Method Composition through Operator Pattern Identification](https://icaps17.icaps-conference.org/workshops/KEPS/proceedingsKEPS.pdf#page=57).

## Swap Pattern
Some planning instances require repeatedly application of the same action(s) with different parameters to swap the value of a certain predicate.
Very common in discretized scenarios where an ``at`` predicate is modified through the usage of ``move`` actions, constrained by a rigid predicate, such as ``connected``.
The resulting method is split in N+1 cases for N swap operators, for every effect:
- Base: nothing to do;
- using operator: try one swap step using operator, mark this step to avoid loops, recursive decomposition, and unmark.

```Lisp
(:action move
  :parameters (?a - agent ?source ?destination - location)
  :precondition (and
    (at ?a ?source)
    (not (at ?a ?destination))
    (connected ?source ?destination)
  )
  :effect (and
    (not (at ?a ?source))
    (at ?a ?destination)
  )
)
```

```Lisp
(:method (swap_at_until_at ?a ?destination)
  base
  ((at ?a ?destination))
  ()
  using_move
  (
    (connected ?current ?intermediate)
    (at ?a ?current)
    (not (at ?a ?goal))
    (not (visited_at ?a ?intermediate))
  )
  (
    (!move ?a ?current ?intermedediate)
    (!!visit_at ?a ?current)
    (swap_at ?a ?destination)
    (!!unvisit_at ?a ?current)
  )
)
```

## Dependency Pattern
In the same way some planning instances require the effects of an action to make another action applicable, fulfilling the preconditions.
Such precondition turns the first action effects into a dependency for the second action preconditions to be satisfied and the action applied.
The resulting method is split in three cases for every effect:
- Goal-satisfied: nothing to do;
- Satisfied: the precondition for the second action is satisfied;
- Unsatisfied: the precondition for the second action is unsatisfied.

```Lisp
(:operator (!buy ?a - agent ?x - object)
  (
    (got_money ?a)
    (not (have ?a ?x))
  )
  ((got_money ?a))
  ((have ?a ?x))
)
(:operator (!give ?a ?b - agent ?x - object)
  (
    (have ?a ?x)
    (not (have ?b ?x))
  )
  ((have ?a ?x))
  (
    (have ?b ?x)
    (happy ?b)
  )
)
```

```Lisp
(:method (dependency_buy_before_give_for_have ?a ?x ?b)
  goal-satisfied
  ((have ?b ?x))
  ()
)
(:method (dependency_buy_before_give_for_have ?a ?x ?b)
  satisfied
  (
    (agent ?a)
    (agent ?b)
    (object ?x)
    (have ?a ?x)
  )
  ((!give ?a ?b ?x))
)
(:method (dependency_buy_before_give_for_have ?a ?x ?b)
  unsatisfied
  (
    (agent ?a)
    (agent ?b)
    (object ?x)
    (not (have ?a ?x))
  )
  (
    (dependency_work_before_buy_for_have ?a ?x)
    (!give ?a ?b ?x)
  )
)
```

## Free Variable Pattern
Once you have the methods the last stage is to convert the goal state into tasks.
Some variables may be free, which means any goal position but the current one achieves ``(not (at ana current))``, or anyone could give anything to ``bob`` to achieve ``(happy bob)``, even ``bob``.
To avoid having a free variable in the top-level tasks a new task is created to explicitly unify the remaining free variables.

```Lisp
(:method (unify_a_x_before_dependency_buy_before_give_for_happy ?b)
  a_x
  (
    (agent ?a)
    (agent ?b)
    (object ?x)
  )
  ((dependency_buy_before_give_for_happy ?a ?x ?b))
)
```