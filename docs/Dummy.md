Based on [Complexity Results for HTN Planning](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.476.6897&rep=rep1&type=pdf)

```Ruby
Algorithm dummy(operators, initial state, goal state)
  create an unordered task list
  create methods set
  Foreach positive goal predicate p in goal state
    create task perform_goal_p
    perform_goal_p can be decomposed into:
    - method finish_goal_p
      - positive precondition p
      - no subtasks
    - method try_o_to_perform_goal_p for each operator o
      - preconditions of o
      - subtasks <mark o, o, perform_goal_p, unmark o>
    add perform_goal_p to task list
  end
  Foreach negative goal predicate p in goal state
    create task perform_goal_not_p
    perform_goal_not_p can be decomposed into:
    - finish_goal_not_p
      - negative precondition p
      - no subtasks
    - try_o_to_perform_goal_not_p for each operator o
      - preconditions of o
      - subtasks <mark o, o, perform_goal_not_p, unmark o>
    add perform_goal_not_p to task list
  end
  Add operator mark o with negative precondition (marked o) and positive effect (marked o)
  Add operator unmark o with negative effect (marked o)
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
      (agent ?a)
      (agent ?b)
      (object ?x)
      (have ?a ?x)
      (not (have ?b ?x))
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
      (agent ?a)
      (object ?x)
      (got_money ?a)
      (not (have ?a ?x))
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
      (agent ?a)
      (agent ?b)
      (object ?x)
      (have ?a ?x)
      (not (have ?b ?x))
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