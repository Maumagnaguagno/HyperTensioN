(define (problem problem)
  (:domain basic)
  (:requirements :strips :negative-preconditions)
  (:objects
    kiwi banjo
  )
  (:init
    (object kiwi)
    (object banjo)
  )
  (:goal
    (and
      (have banjo)
    )
  )
)