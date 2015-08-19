(define (domain basic)
  (:requirements :strips :negative-preconditions)

  (:predicates
    (have ?a)
    (object ?a)
  )

  (:action pickup
    :parameters (?a)
    :precondition
      (and
        (object ?a)
        (not (have ?a))
      )
    :effect
      (and
        (have ?a)
      )
  )

  (:action drop
    :parameters (?a)
    :precondition
      (and
        (have ?a)
      )
    :effect
      (and
        (not (have ?a))
      )
  )
)