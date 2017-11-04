(define (domain tsp)
  (:requirements :strips :negative-preconditions)
  (:predicates
    (at ?pos)
    (connected ?start ?finish)
    (visited ?finish)
  )

  (:action move
    :parameters (?start ?finish)
    :precondition (and
      (at ?start)
      (connected ?start ?finish)
      (not (visited ?finish))
    )
    :effect (and
      (at ?finish)
      (visited ?finish)
      (not (at ?start))
    )
  )
)