(define (problem problem)
  (:domain basic)
  (:requirements :strips :negative-preconditions)
  (:objects
    kiwi banjo
  )
  (:init
  )
  (:goal
    (and
      (have banjo)
    )
  )
)