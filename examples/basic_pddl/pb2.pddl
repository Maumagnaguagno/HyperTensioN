(define (problem problem)
  (:domain basic)
  (:requirements :strips)
  (:objects
    kiwi banjo
  )
  (:init
  )
  (:goal
    (and
      (have banjo)
      (have kiwi)
    )
  )
)