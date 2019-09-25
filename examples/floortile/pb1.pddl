(define (problem pb1)
  (:domain floortile)
  (:objects
    top_left top_right bottom_left bottom_right - tile
    robot1 - robot
    white black - color
  )
  (:init
    (robot-at robot1 top_right) (clear top_left)
    (clear bottom_right) (clear bottom_left)
    (robot-has robot1 white)
    (available-color white) (available-color black)
    (up top_right bottom_right) (up top_left bottom_left)
    (down bottom_right top_right) (down bottom_left top_left)
    (left top_right top_left) (left bottom_right bottom_left)
    (right top_left top_right) (right bottom_left bottom_right)
  )
  (:goal (and
    (painted top_right black)
    (painted bottom_left white)
  ))
)