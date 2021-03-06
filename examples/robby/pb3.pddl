(define (problem pb3)
  (:domain robby)
  (:objects
    robby - robot
    h1 h2up h2down h3up h3down h4 h5 h6 - hallway
    r1 r2 r3 r4 - room
    b1 b2 b3 b4 b5 - beacon
  )
  (:init
    (at robby h1)
    (in b1 r1)
    (in b2 h2up)
    (in b3 h3down)
    (in b4 r3)
    (in b5 r4)
    (connected h1 h2up) (connected h2up h1)
    (connected h1 h2down) (connected h2down h1)
    (connected h2up h3up) (connected h3up h2up)
    (connected h2down h3down) (connected h3down h2down)
    (connected h3up h4) (connected h4 h3up)
    (connected h3down h4) (connected h4 h3down)
    (connected h4 h5) (connected h5 h4)
    (connected h5 h6) (connected h6 h5)
    (connected r1 h1) (connected h1 r1)
    (connected r1 h2down) (connected h2down r1)
    (connected r2 h3up) (connected h3up r2)
    (connected r2 h3down) (connected h3down r2)
    (connected r3 h3up) (connected h3up r3)
    (connected r4 h5) (connected h5 r4)
  )
  (:goal (and
    (reported robby b1)
    (reported robby b2)
    (reported robby b3)
    (reported robby b4)
    (reported robby b5)
    (at robby h6)
  ))
)