(define (domain robby)
  (:requirements :strips :typing :negative-preconditions)

  (:types
    robot beacon location - object
    hallway room - location
  )

  (:predicates
    (at ?bot - robot ?place - location)
    (in ?beacon - beacon ?place - location)
    (connected ?place1 - location ?place2 - location)
    (reported ?bot - robot ?beacon - beacon)
  )

  (:action enter
    :parameters (?bot - robot ?source - hallway ?destination - room)
    :precondition (and
      (at ?bot ?source)
      (not (at ?bot ?destination))
      (connected ?source ?destination)
    )
    :effect (and
      (not (at ?bot ?source))
      (at ?bot ?destination)
    )
  )

  (:action exit
    :parameters (?bot - robot ?source - room ?destination - hallway)
    :precondition (and
      (at ?bot ?source)
      (not (at ?bot ?destination))
      (connected ?source ?destination)
    )
    :effect (and
      (not (at ?bot ?source))
      (at ?bot ?destination)
    )
  )

  (:action move
    :parameters (?bot - robot ?source - hallway ?destination - hallway)
    :precondition (and
      (at ?bot ?source)
      (not (at ?bot ?destination))
      (connected ?source ?destination)
    )
    :effect (and
      (not (at ?bot ?source))
      (at ?bot ?destination)
    )
  )

  (:action report
    :parameters (?bot - robot ?source - location ?beacon - beacon)
    :precondition (and
      (at ?bot ?source)
      (in ?beacon ?source)
      (not (reported ?bot ?beacon))
    )
    :effect (reported ?bot ?beacon)
  )
)