(define (problem pb1)
  (:domain dependency)
  (:requirements :strips :typing :negative-preconditions)
  (:objects
    ana bob - agent
    gift - object
  )
  (:init (have ana gift))
  (:goal (and (happy bob)))
)