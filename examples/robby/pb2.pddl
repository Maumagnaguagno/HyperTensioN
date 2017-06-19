(define (problem pb2)
  (:domain robby)
  (:objects
    robby - robot
    left leftmiddle rightmiddle right - hallway
    room1lm room2lm room3lm room4rm room5r - room
    beaconr1 beaconr2 beaconr3 beaconright - beacon
  )
  (:init
    (at robby left)
    (in beaconr1 room1lm)
    (in beaconr2 room2lm)
    (in beaconr3 room3lm)
    (in beaconright right)
    (connected left leftmiddle) (connected leftmiddle left)
    (connected leftmiddle rightmiddle) (connected rightmiddle leftmiddle)
    (connected rightmiddle right) (connected right rightmiddle)
    (connected room1lm leftmiddle) (connected leftmiddle room1lm)
    (connected room2lm leftmiddle) (connected leftmiddle room2lm)
    (connected room3lm leftmiddle) (connected leftmiddle room3lm)
    (connected room4rm rightmiddle) (connected rightmiddle room4rm)
    (connected room5r right) (connected right room5r)
  )
  (:goal (and
    (reported robby beaconr1)
    (reported robby beaconr2)
    (reported robby beaconr3)
    (reported robby beaconright)
    (at robby right)
  ))
)