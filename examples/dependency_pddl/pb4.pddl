(define (problem pb4)
  (:domain dependency)
  (:requirements :strips :typing :negative-preconditions)
  (:objects
    ana bob - agent
    gift - object
  )
  (:init)
  (:goal (and (have bob gift)))
)