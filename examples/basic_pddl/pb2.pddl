(define (problem pb2)
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
      (have kiwi)
    )
  )
)