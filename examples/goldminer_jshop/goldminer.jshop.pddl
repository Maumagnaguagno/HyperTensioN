; Generated by Hype
(define (domain goldminer)
  (:requirements :strips :negative-preconditions)

  (:predicates
    (at ?agent ?from)
    (adjacent ?from ?to)
    (blocked ?to)
    (on ?gold ?where)
    (has ?agent ?gold)
    (visited ?agent ?pos)
    (dibs ?gold)
    (next ?agent ?other)
    (duty ?other)
  )

  (:action move
    :parameters (?agent ?from ?to)
    :precondition
      (and
        (at ?agent ?from)
        (adjacent ?from ?to)
        (not (blocked ?to))
      )
    :effect
      (and
        (at ?agent ?to)
        (not (at ?agent ?from))
      )
  )

  (:action pick
    :parameters (?agent ?gold ?where)
    :precondition
      (and
        (at ?agent ?where)
        (on ?gold ?where)
      )
    :effect
      (and
        (has ?agent ?gold)
        (not (on ?gold ?where))
      )
  )

  (:action drop
    :parameters (?agent ?gold ?where)
    :precondition
      (and
        (at ?agent ?where)
      )
    :effect
      (and
        (on ?gold ?where)
        (not (has ?agent ?gold))
      )
  )

  (:action visit
    :parameters (?agent ?pos)
    :precondition
      (and
      )
    :effect
      (and
        (visited ?agent ?pos)
      )
  )

  (:action unvisit
    :parameters (?agent ?pos)
    :precondition
      (and
      )
    :effect
      (and
        (not (visited ?agent ?pos))
      )
  )

  (:action see
    :parameters (?gold)
    :precondition
      (and
      )
    :effect
      (and
        (dibs ?gold)
      )
  )

  (:action shift
    :parameters (?agent)
    :precondition
      (and
        (next ?agent ?other)
      )
    :effect
      (and
        (duty ?other)
        (not (duty ?agent))
      )
  )
)