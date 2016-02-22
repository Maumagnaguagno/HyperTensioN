(define (problem pb3)
  (:domain dependency)
  (:requirements :strips :typing :negative-preconditions)
  (:objects
    ana bob - agent
    gift - object
  )
  (:init)
  (:goal (and (got_money bob)))
)