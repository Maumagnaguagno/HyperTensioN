(define (problem pb1)
  (:domain tsp)
  (:objects Boston NewYork Pittsburgh Toronto Albany)
  (:init
    ; Directed graph
    (connected Boston NewYork)
    (connected NewYork Boston)
    (connected Pittsburgh Boston)
    (connected Boston Pittsburgh)
    (connected Pittsburgh NewYork)
    (connected NewYork Pittsburgh)
    (connected Toronto Pittsburgh)
    (connected Toronto NewYork)
    (connected NewYork Toronto)
    (connected NewYork Albany)
    (connected Albany NewYork)
    (connected Albany Toronto)
    (connected Toronto Albany)
    ; Start
    (at Pittsburgh)
  )

  (:goal (and
    (at Pittsburgh)
    (visited Boston)
    (visited NewYork)
    (visited Pittsburgh)
    (visited Toronto)
    (visited Albany)
  ))
)