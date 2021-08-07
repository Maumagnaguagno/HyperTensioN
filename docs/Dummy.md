# Dummy
Hype is able to extend classical planning instances and generate methods and tasks to solve them with a HTN planner using [Patterns](Patterns.md) and Dummy.
Dummy is based on the transformation of STRIPS to HTN presented in [Complexity Results for HTN Planning - 3.3 Expressivity: HTNs versus STRIPS representation](https://www.cs.umd.edu/~nau/papers/erol1996complexity.pdf).
The current [implementation](../extensions/Dummy.rb) of the following algorithm has been expanded to limit the amount of repeated action application.
This limitation purpose it to avoid infinite loops as some actions may undo previous effects, by marking actions as visited once applied and only applying actions not visited more than a certain amount of times.
The repetition expands the amount of methods of ``perform_goal_p/not_p try_o_to_perform_goal_p/not_p n``, ``visit`` and ``unvist`` operators.
Some problems may require more repetitions to satisfy a goal state.

Note that the original algorithm can be used with [stochastic search](../examples/experiments/Stochastic.rb) and no repetition control.
The new Hyper compiler does not use ``generate`` and requires calls to ``each`` to be replaced with ``shuffle!.each`` in the domain.

```Ruby
def dummy(operators, initial state, goal state)
  create an unordered task list
  create methods set
  for positive goal predicate p in goal state
    create task perform_goal_p
    perform_goal_p can be decomposed into:
    - method finish_goal_p
      - positive precondition p
      - subtasks []
    - method try_o_to_perform_goal_p for each o in operators
      - preconditions of o
      - subtasks [visit o, o, perform_goal_p, unvisit o]
    add perform_goal_p to task list
  end
  for negative goal predicate p in goal state
    create task perform_goal_not_p
    perform_goal_not_p can be decomposed into:
    - finish_goal_not_p
      - negative precondition p
      - subtasks []
    - try_o_to_perform_goal_not_p for each o in operators
      - preconditions of o
      - subtasks [visit o, o, perform_goal_not_p, unvisit o]
    add perform_goal_not_p to task list
  end
  define visit o with negative precondition (visited o) and positive effect (visited o) to operators
  define unvisit o with negative effect (visited o) to operators
  return <operators, methods, initial state, task list>
end
```

Example of PDDL to JSHOP:

```Lisp
(define (domain dependency)
  (:requirements :strips :typing :negative-preconditions)
  (:predicates (have ?a ?x) (got_money ?a) (happy ?a))
  (:action work
    :parameters (?a - agent)
    :precondition (and (not (got_money ?a)))
    :effect (and (not (happy ?a)) (got_money ?a))
  )
  (:action buy
    :parameters (?a - agent ?x - object)
    :precondition (and (got_money ?a) (not (have ?a ?x)))
    :effect (and (not (got_money ?a)) (have ?a ?x))
  )
  (:action give
    :parameters (?a ?b - agent ?x - object)
    :precondition (and (have ?a ?x) (not (have ?b ?x)))
    :effect (and (not (have ?a ?x)) (have ?b ?x) (happy ?b))
  )
)
```

```Lisp
(defdomain dependency (
  ; Operators
  (:operator (!work ?a)
    ((agent ?a) (not (got_money ?a)))
    ((happy ?a))
    ((got_money ?a))
  )
  (:operator (!buy ?a ?x)
    ((agent ?a) (object ?x) (got_money ?a) (not (have ?a ?x)))
    ((got_money ?a))
    ((have ?a ?x))
  )
  (:operator (!give ?a ?b ?x)
    (
      (agent ?a) (agent ?b) (object ?x)
      (have ?a ?x) (not (have ?b ?x))
    )
    ((have ?a ?x))
    ((have ?b ?x) (happy ?b))
  )
  (:operator (!!visit_work_1 ?a)
    ((not (visited_work_1 ?a)))
    ()
    ((visited_work_1 ?a))
  )
  (:operator (!!unvisit_work_1 ?a)
    ()
    ((visited_work_1 ?a))
    ()
  )
  (:operator (!!visit_buy_1 ?a ?x)
    ((not (visited_buy_1 ?a ?x)))
    ()
    ((visited_buy_1 ?a ?x))
  )
  (:operator (!!unvisit_buy_1 ?a ?x)
    ()
    ((visited_buy_1 ?a ?x))
    ()
  )
  (:operator (!!visit_give_1 ?a ?b ?x)
    ((not (visited_give_1 ?a ?b ?x)))
    ()
    ((visited_give_1 ?a ?b ?x))
  )
  (:operator (!!unvisit_give_1 ?a ?b ?x)
    ()
    ((visited_give_1 ?a ?b ?x))
    ()
  )
  ; Methods
  (:method (perform_goal_happy_bob)
    finish_perform_goal_happy_bob
    ((happy bob))
    ()
  )
  (:method (perform_goal_happy_bob)
    try_work_to_perform_goal_happy_bob1
    (
      (agent ?a)
      (not (got_money ?a))
    )
    (
      (!!visit_work_1 ?a)
      (!work ?a)
      (perform_goal_happy_bob)
      (!!unvisit_work_1 ?a)
    )
  )
  (:method (perform_goal_happy_bob)
    try_buy_to_perform_goal_happy_bob1
    (
      (agent ?a) (object ?x)
      (got_money ?a) (not (have ?a ?x))
    )
    (
      (!!visit_buy_1 ?a ?x)
      (!buy ?a ?x)
      (perform_goal_happy_bob)
      (!!unvisit_buy_1 ?a ?x)
    )
  )
  (:method (perform_goal_happy_bob)
    try_give_to_perform_goal_happy_bob1
    (
      (agent ?a) (agent ?b) (object ?x)
      (have ?a ?x) (not (have ?b ?x))
    )
    (
      (!!visit_give_1 ?a ?b ?x)
      (!give ?a ?b ?x)
      (perform_goal_happy_bob)
      (!!unvisit_give_1 ?a ?b ?x)
    )
  )
))
```