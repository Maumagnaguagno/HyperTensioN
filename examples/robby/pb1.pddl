(define (problem pb1)
  (:domain robby)
  (:objects
    robby - robot
    left middle right - hallway
    room1 - room
    beacon1 - beacon
  )
  (:init
    (at robby left)
    (in beacon1 room1)
    (connected middle room1) (connected room1 middle)
    (connected left middle) (connected middle left)
    (connected middle right) (connected right middle)
  )
  (:goal (and
    (reported robby beacon1)
    (at robby right)
  ))
)