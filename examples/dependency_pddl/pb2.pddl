(define (problem pb2)
  (:domain dependency)
  (:requirements :strips :typing :negative-preconditions)
  (:objects
    ana bob - agent
    gift - object
  )
  (:init
  )
  (:goal
    (and
      (happy bob)
    )
  )
)