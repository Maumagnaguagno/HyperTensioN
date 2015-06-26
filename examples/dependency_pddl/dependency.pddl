(define (domain dependency)
  (:requirements :strips :typing :negative-preconditions)

  (:predicates
    (have ?a ?x)
    (got_money ?a)
    (happy ?a)
  )

  (:action work
    :parameters (?a - agent)
    :precondition
      (and
        (not (got_money ?a))
      )
    :effect
      (and
        (not (happy ?a))
        (got_money ?a)
      )
  )

  (:action buy
    :parameters (?a - agent ?x - object)
    :precondition
      (and
        (not (have ?a ?x))
      )
    :effect
      (and
        (have ?a ?x)
      )
  )

  (:action give
    :parameters (?a ?b - agent ?x - object)
    :precondition
      (and
        (have ?a ?x)
        (not (have ?b ?x))
      )
    :effect
      (and
        (not (have ?a ?x))
        (have ?b ?x)
        (happy ?b)
      )
  )
)