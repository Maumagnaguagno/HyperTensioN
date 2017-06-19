(define (domain tsp)
  (:requirements :strips :typing :negative-preconditions)
  (:types node)
  (:predicates
    (at ?pos - node)
    (connected ?start ?finish - node)
    (visited ?finish - node)
  )

  (:action move
    :parameters (?start ?finish - node)
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