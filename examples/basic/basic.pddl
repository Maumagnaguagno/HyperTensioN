(define (domain basic)
  (:requirements :strips :negative-preconditions)
  (:predicates (have ?a))

  (:action pickup
    :parameters (?a)
    :precondition (not (have ?a))
    :effect (have ?a)
  )

  (:action drop
    :parameters (?a)
    :precondition (have ?a)
    :effect (not (have ?a))
  )
)