# Dummy
Hype is able to extend classical planning instances and generate methods and tasks to solve them with a HTN planner based on the transformation of STRIPS to HTN presented in [Complexity Results for HTN Planning - 3.3 Expressivity: HTNs versus STRIPS representation](http://www.cs.umd.edu/~nau/papers/erol1996complexity.pdf).
The current [implementation](../extensions/Dummy.rb) of the following algorithm has been expanded to limit the amount of repeated action application.
This limitation purpose it to avoid infinite loops as some actions may undo previous effects, by marking actions once applied and only applying actions not marked more than a certain amount of times.
The repetition expands the amount of methods of ``perform_goal_p/not_p try_o_to_perform_goal_p/not_p n``, ``mark`` and ``unmark`` operators.
Some problems may require more repetitions to satisfy a goal state.
Note that the original algorithm can be used with [stochastic search](../examples/experiments/Stochastic.rb) and no repetition control.

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
      - subtasks [mark o, o, perform_goal_p, unmark o]
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
      - subtasks [mark o, o, perform_goal_not_p, unmark o]
    add perform_goal_not_p to task list
  end
  add mark o with negative precondition (marked o) and positive effect (marked o) to operators
  add unmark o with negative effect (marked o) to operators
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
  (:operator (!!mark_work_1 ?a)
    ((not (marked_work_1 ?a)))
    ()
    ((marked_work_1 ?a))
  )
  (:operator (!!unmark_work_1 ?a)
    ()
    ((marked_work_1 ?a))
    ()
  )
  (:operator (!!mark_buy_1 ?a ?x)
    ((not (marked_buy_1 ?a ?x)))
    ()
    ((marked_buy_1 ?a ?x))
  )
  (:operator (!!unmark_buy_1 ?a ?x)
    ()
    ((marked_buy_1 ?a ?x))
    ()
  )
  (:operator (!!mark_give_1 ?a ?b ?x)
    ((not (marked_give_1 ?a ?b ?x)))
    ()
    ((marked_give_1 ?a ?b ?x))
  )
  (:operator (!!unmark_give_1 ?a ?b ?x)
    ()
    ((marked_give_1 ?a ?b ?x))
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
      (!!mark_work_1 ?a)
      (!work ?a)
      (perform_goal_happy_bob)
      (!!unmark_work_1 ?a)
    )
  )
  (:method (perform_goal_happy_bob)
    try_buy_to_perform_goal_happy_bob1
    (
      (agent ?a) (object ?x)
      (got_money ?a) (not (have ?a ?x))
    )
    (
      (!!mark_buy_1 ?a ?x)
      (!buy ?a ?x)
      (perform_goal_happy_bob)
      (!!unmark_buy_1 ?a ?x)
    )
  )
  (:method (perform_goal_happy_bob)
    try_give_to_perform_goal_happy_bob1
    (
      (agent ?a) (agent ?b) (object ?x)
      (have ?a ?x) (not (have ?b ?x))
    )
    (
      (!!mark_give_1 ?a ?b ?x)
      (!give ?a ?b ?x)
      (perform_goal_happy_bob)
      (!!unmark_give_1 ?a ?b ?x)
    )
  )
))
```