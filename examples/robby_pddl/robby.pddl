(define (domain robby)
  (:requirements :strips :typing :negative-preconditions)

  (:types
    robot beacon location - object
    hallway room - location
  )

  (:predicates
    (robot ?bot)
    (beacon ?thing)
    (room ?place)
    (hallway ?place)
    (at ?bot - robot ?place - location)
    (in ?thing - beacon ?place - location)
    (connected ?place1 - location ?place2 - location)
    (reported ?bot - robot ?thing - beacon)
  )

  (:action enter
    :parameters (?bot - robot ?source - hallway ?destination - room)
    :precondition
      (and
        (at ?bot ?source)
        (not (at ?bot ?destination))
        (connected ?source ?destination)
      )
    :effect
      (and
        (not (at ?bot ?source))
        (at ?bot ?destination)
      )
  )

  (:action exit
    :parameters (?bot - robot ?source - room ?destination - hallway)
    :precondition
      (and
        (at ?bot ?source)
        (not (at ?bot ?destination))
        (connected ?source ?destination)
      )
    :effect
      (and
        (not (at ?bot ?source))
        (at ?bot ?destination)
      )
  )

  (:action move
    :parameters (?bot - robot ?source - hallway ?destination - hallway)
    :precondition
      (and
        (at ?bot ?source)
        (not (at ?bot ?destination))
        (connected ?source ?destination)
      )
    :effect
      (and
        (not (at ?bot ?source))
        (at ?bot ?destination)
      )
  )

  (:action report
    :parameters (?bot - robot ?source - location ?thing - beacon)
    :precondition
      (and
        (at ?bot ?source)
        (in ?thing ?source)
        (not (reported ?bot ?thing))
      )
    :effect
      (and
        (reported ?bot ?thing)
      )
  )
)