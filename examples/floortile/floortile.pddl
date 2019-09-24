(define (domain floortile)
  (:requirements :strips :typing)
  (:types robot tile color)

  (:predicates
    (robot-at ?r - robot ?x - tile)
    (up ?x ?y - tile)
    (down ?x ?y - tile)
    (right ?x ?y - tile)
    (left ?x ?y - tile)
    (clear ?x - tile)
    (painted ?x - tile ?c - color)
    (robot-has ?r - robot ?c - color)
    (available-color ?c - color)
  )

  (:action change-color
    :parameters (?r - robot ?c ?c2 - color)
    :precondition (and (robot-has ?r ?c) (available-color ?c2))
    :effect (and (not (robot-has ?r ?c)) (robot-has ?r ?c2))
  )

  (:action paint-up
    :parameters (?r - robot ?y ?x - tile ?c - color)
    :precondition (and (robot-has ?r ?c) (robot-at ?r ?x) (up ?y ?x) (clear ?y))
    :effect (and (not (clear ?y)) (painted ?y ?c))
  )

  (:action paint-down
    :parameters (?r - robot ?y ?x - tile ?c - color)
    :precondition (and (robot-has ?r ?c) (robot-at ?r ?x) (down ?y ?x) (clear ?y))
    :effect (and (not (clear ?y)) (painted ?y ?c))
  )

  ; Robot movements
  (:action up
    :parameters (?r - robot ?x ?y - tile)
    :precondition (and (robot-at ?r ?x) (up ?y ?x) (clear ?y))
    :effect (and (robot-at ?r ?y) (not (robot-at ?r ?x)) (clear ?x) (not (clear ?y)))
  )

  (:action down
    :parameters (?r - robot ?x ?y - tile)
    :precondition (and (robot-at ?r ?x) (down ?y ?x) (clear ?y))
    :effect (and (robot-at ?r ?y) (not (robot-at ?r ?x)) (clear ?x) (not (clear ?y)))
  )

  (:action right
    :parameters (?r - robot ?x ?y - tile)
    :precondition (and (robot-at ?r ?x) (right ?y ?x) (clear ?y))
    :effect (and (robot-at ?r ?y) (not (robot-at ?r ?x)) (clear ?x) (not (clear ?y)))
  )

  (:action left
    :parameters (?r - robot ?x ?y - tile)
    :precondition (and (robot-at ?r ?x) (left ?y ?x) (clear ?y))
    :effect (and (robot-at ?r ?y) (not (robot-at ?r ?x)) (clear ?x) (not (clear ?y)))
  )
)