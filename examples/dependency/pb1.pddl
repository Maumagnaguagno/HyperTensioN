(define (problem pb1)
  (:domain dependency)
  (:objects
    ana bob - agent
    gift - object
  )
  (:init (have ana gift))
  (:goal (happy bob))
)