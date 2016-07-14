(define (problem pb4)
  (:domain dependency)
  (:objects
    ana bob - agent
    gift - object
  )
  (:init)
  (:goal (and (have bob gift)))
)