(define (domain goldminer)
  (:requirements :strips :negative-preconditions)

  (:predicates
    (adjacent ?from ?to)
    (at ?agent ?from)
    (blocked ?to)
    (have ?agent ?gold)
    (on ?gold ?drop_position)
  )

  (:action move
    :parameters (?agent ?from ?to)
    :precondition (and
      (at ?agent ?from)
      (adjacent ?from ?to)
      (not (blocked ?from))
      (not (blocked ?to))
    )
    :effect (and
      (at ?agent ?to)
      (not (at ?agent ?from))
    )
  )

  (:action pick
    :parameters (?agent ?gold ?pick_position)
    :precondition (and
      (at ?agent ?pick_position)
      (on ?gold ?pick_position)
      (not (blocked ?pick_position))
    )
    :effect (and
      (have ?agent ?gold)
      (not (on ?gold ?pick_position))
    )
  )

  (:action drop
    :parameters (?agent ?gold ?drop_position)
    :precondition (and
      (at ?agent ?drop_position)
      (have ?agent ?gold)
      (not (blocked ?drop_position))
    )
    :effect (and
      (on ?gold ?drop_position)
      (not (have ?agent ?gold))
    )
  )
)