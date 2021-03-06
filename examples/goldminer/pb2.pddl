(define (problem pb2)
  (:domain goldminer)
  (:objects
    ag1
    g1 g2 g3
    p0_0 p1_0 p2_0 p3_0 p4_0 p5_0 p6_0 p7_0 p8_0 p9_0
    p0_1 p1_1 p2_1 p3_1 p4_1 p5_1 p6_1 p7_1 p8_1 p9_1
    p0_2 p1_2 p2_2 p3_2 p4_2 p5_2 p6_2 p7_2 p8_2 p9_2
    p0_3 p1_3 p2_3 p3_3 p4_3 p5_3 p6_3 p7_3 p8_3 p9_3
    p0_4 p1_4 p2_4 p3_4 p4_4 p5_4 p6_4 p7_4 p8_4 p9_4
    p0_5 p1_5 p2_5 p3_5 p4_5 p5_5 p6_5 p7_5 p8_5 p9_5
    p0_6 p1_6 p2_6 p3_6 p4_6 p5_6 p6_6 p7_6 p8_6 p9_6
    p0_7 p1_7 p2_7 p3_7 p4_7 p5_7 p6_7 p7_7 p8_7 p9_7
    p0_8 p1_8 p2_8 p3_8 p4_8 p5_8 p6_8 p7_8 p8_8 p9_8
    p0_9 p1_9 p2_9 p3_9 p4_9 p5_9 p6_9 p7_9 p8_9 p9_9
  )
  (:init
    (adjacent p0_0 p1_0) (adjacent p1_0 p0_0)
    (adjacent p0_0 p0_1) (adjacent p0_1 p0_0)
    (adjacent p1_0 p2_0) (adjacent p2_0 p1_0)
    (adjacent p1_0 p1_1) (adjacent p1_1 p1_0)
    (adjacent p2_0 p3_0) (adjacent p3_0 p2_0)
    (adjacent p2_0 p2_1) (adjacent p2_1 p2_0)
    (adjacent p3_0 p4_0) (adjacent p4_0 p3_0)
    (adjacent p3_0 p3_1) (adjacent p3_1 p3_0)
    (adjacent p4_0 p5_0) (adjacent p5_0 p4_0)
    (adjacent p4_0 p4_1) (adjacent p4_1 p4_0)
    (adjacent p5_0 p6_0) (adjacent p6_0 p5_0)
    (adjacent p5_0 p5_1) (adjacent p5_1 p5_0)
    (adjacent p6_0 p7_0) (adjacent p7_0 p6_0)
    (adjacent p6_0 p6_1) (adjacent p6_1 p6_0)
    (adjacent p7_0 p8_0) (adjacent p8_0 p7_0)
    (adjacent p7_0 p7_1) (adjacent p7_1 p7_0)
    (adjacent p8_0 p9_0) (adjacent p9_0 p8_0)
    (adjacent p8_0 p8_1) (adjacent p8_1 p8_0)
    (adjacent p9_0 p9_1) (adjacent p9_1 p9_0)
    (adjacent p0_1 p1_1) (adjacent p1_1 p0_1)
    (adjacent p0_1 p0_2) (adjacent p0_2 p0_1)
    (adjacent p1_1 p2_1) (adjacent p2_1 p1_1)
    (adjacent p1_1 p1_2) (adjacent p1_2 p1_1)
    (adjacent p2_1 p3_1) (adjacent p3_1 p2_1)
    (adjacent p2_1 p2_2) (adjacent p2_2 p2_1)
    (adjacent p3_1 p4_1) (adjacent p4_1 p3_1)
    (adjacent p3_1 p3_2) (adjacent p3_2 p3_1)
    (adjacent p4_1 p5_1) (adjacent p5_1 p4_1)
    (adjacent p4_1 p4_2) (adjacent p4_2 p4_1)
    (adjacent p5_1 p6_1) (adjacent p6_1 p5_1)
    (adjacent p5_1 p5_2) (adjacent p5_2 p5_1)
    (adjacent p6_1 p7_1) (adjacent p7_1 p6_1)
    (adjacent p6_1 p6_2) (adjacent p6_2 p6_1)
    (adjacent p7_1 p8_1) (adjacent p8_1 p7_1)
    (adjacent p7_1 p7_2) (adjacent p7_2 p7_1)
    (adjacent p8_1 p9_1) (adjacent p9_1 p8_1)
    (adjacent p8_1 p8_2) (adjacent p8_2 p8_1)
    (adjacent p9_1 p9_2) (adjacent p9_2 p9_1)
    (adjacent p0_2 p1_2) (adjacent p1_2 p0_2)
    (adjacent p0_2 p0_3) (adjacent p0_3 p0_2)
    (adjacent p1_2 p2_2) (adjacent p2_2 p1_2)
    (adjacent p1_2 p1_3) (adjacent p1_3 p1_2)
    (adjacent p2_2 p3_2) (adjacent p3_2 p2_2)
    (adjacent p2_2 p2_3) (adjacent p2_3 p2_2)
    (adjacent p3_2 p4_2) (adjacent p4_2 p3_2)
    (adjacent p3_2 p3_3) (adjacent p3_3 p3_2)
    (adjacent p4_2 p5_2) (adjacent p5_2 p4_2)
    (adjacent p4_2 p4_3) (adjacent p4_3 p4_2)
    (adjacent p5_2 p6_2) (adjacent p6_2 p5_2)
    (adjacent p5_2 p5_3) (adjacent p5_3 p5_2)
    (adjacent p6_2 p7_2) (adjacent p7_2 p6_2)
    (adjacent p6_2 p6_3) (adjacent p6_3 p6_2)
    (adjacent p7_2 p8_2) (adjacent p8_2 p7_2)
    (adjacent p7_2 p7_3) (adjacent p7_3 p7_2)
    (adjacent p8_2 p9_2) (adjacent p9_2 p8_2)
    (adjacent p8_2 p8_3) (adjacent p8_3 p8_2)
    (adjacent p9_2 p9_3) (adjacent p9_3 p9_2)
    (adjacent p0_3 p1_3) (adjacent p1_3 p0_3)
    (adjacent p0_3 p0_4) (adjacent p0_4 p0_3)
    (adjacent p1_3 p2_3) (adjacent p2_3 p1_3)
    (adjacent p1_3 p1_4) (adjacent p1_4 p1_3)
    (adjacent p2_3 p3_3) (adjacent p3_3 p2_3)
    (adjacent p2_3 p2_4) (adjacent p2_4 p2_3)
    (adjacent p3_3 p4_3) (adjacent p4_3 p3_3)
    (adjacent p3_3 p3_4) (adjacent p3_4 p3_3)
    (adjacent p4_3 p5_3) (adjacent p5_3 p4_3)
    (adjacent p4_3 p4_4) (adjacent p4_4 p4_3)
    (adjacent p5_3 p6_3) (adjacent p6_3 p5_3)
    (adjacent p5_3 p5_4) (adjacent p5_4 p5_3)
    (adjacent p6_3 p7_3) (adjacent p7_3 p6_3)
    (adjacent p6_3 p6_4) (adjacent p6_4 p6_3)
    (adjacent p7_3 p8_3) (adjacent p8_3 p7_3)
    (adjacent p7_3 p7_4) (adjacent p7_4 p7_3)
    (adjacent p8_3 p9_3) (adjacent p9_3 p8_3)
    (adjacent p8_3 p8_4) (adjacent p8_4 p8_3)
    (adjacent p9_3 p9_4) (adjacent p9_4 p9_3)
    (adjacent p0_4 p1_4) (adjacent p1_4 p0_4)
    (adjacent p0_4 p0_5) (adjacent p0_5 p0_4)
    (adjacent p1_4 p2_4) (adjacent p2_4 p1_4)
    (adjacent p1_4 p1_5) (adjacent p1_5 p1_4)
    (adjacent p2_4 p3_4) (adjacent p3_4 p2_4)
    (adjacent p2_4 p2_5) (adjacent p2_5 p2_4)
    (adjacent p3_4 p4_4) (adjacent p4_4 p3_4)
    (adjacent p3_4 p3_5) (adjacent p3_5 p3_4)
    (adjacent p4_4 p5_4) (adjacent p5_4 p4_4)
    (adjacent p4_4 p4_5) (adjacent p4_5 p4_4)
    (adjacent p5_4 p6_4) (adjacent p6_4 p5_4)
    (adjacent p5_4 p5_5) (adjacent p5_5 p5_4)
    (adjacent p6_4 p7_4) (adjacent p7_4 p6_4)
    (adjacent p6_4 p6_5) (adjacent p6_5 p6_4)
    (adjacent p7_4 p8_4) (adjacent p8_4 p7_4)
    (adjacent p7_4 p7_5) (adjacent p7_5 p7_4)
    (adjacent p8_4 p9_4) (adjacent p9_4 p8_4)
    (adjacent p8_4 p8_5) (adjacent p8_5 p8_4)
    (adjacent p9_4 p9_5) (adjacent p9_5 p9_4)
    (adjacent p0_5 p1_5) (adjacent p1_5 p0_5)
    (adjacent p0_5 p0_6) (adjacent p0_6 p0_5)
    (adjacent p1_5 p2_5) (adjacent p2_5 p1_5)
    (adjacent p1_5 p1_6) (adjacent p1_6 p1_5)
    (adjacent p2_5 p3_5) (adjacent p3_5 p2_5)
    (adjacent p2_5 p2_6) (adjacent p2_6 p2_5)
    (adjacent p3_5 p4_5) (adjacent p4_5 p3_5)
    (adjacent p3_5 p3_6) (adjacent p3_6 p3_5)
    (adjacent p4_5 p5_5) (adjacent p5_5 p4_5)
    (adjacent p4_5 p4_6) (adjacent p4_6 p4_5)
    (adjacent p5_5 p6_5) (adjacent p6_5 p5_5)
    (adjacent p5_5 p5_6) (adjacent p5_6 p5_5)
    (adjacent p6_5 p7_5) (adjacent p7_5 p6_5)
    (adjacent p6_5 p6_6) (adjacent p6_6 p6_5)
    (adjacent p7_5 p8_5) (adjacent p8_5 p7_5)
    (adjacent p7_5 p7_6) (adjacent p7_6 p7_5)
    (adjacent p8_5 p9_5) (adjacent p9_5 p8_5)
    (adjacent p8_5 p8_6) (adjacent p8_6 p8_5)
    (adjacent p9_5 p9_6) (adjacent p9_6 p9_5)
    (adjacent p0_6 p1_6) (adjacent p1_6 p0_6)
    (adjacent p0_6 p0_7) (adjacent p0_7 p0_6)
    (adjacent p1_6 p2_6) (adjacent p2_6 p1_6)
    (adjacent p1_6 p1_7) (adjacent p1_7 p1_6)
    (adjacent p2_6 p3_6) (adjacent p3_6 p2_6)
    (adjacent p2_6 p2_7) (adjacent p2_7 p2_6)
    (adjacent p3_6 p4_6) (adjacent p4_6 p3_6)
    (adjacent p3_6 p3_7) (adjacent p3_7 p3_6)
    (adjacent p4_6 p5_6) (adjacent p5_6 p4_6)
    (adjacent p4_6 p4_7) (adjacent p4_7 p4_6)
    (adjacent p5_6 p6_6) (adjacent p6_6 p5_6)
    (adjacent p5_6 p5_7) (adjacent p5_7 p5_6)
    (adjacent p6_6 p7_6) (adjacent p7_6 p6_6)
    (adjacent p6_6 p6_7) (adjacent p6_7 p6_6)
    (adjacent p7_6 p8_6) (adjacent p8_6 p7_6)
    (adjacent p7_6 p7_7) (adjacent p7_7 p7_6)
    (adjacent p8_6 p9_6) (adjacent p9_6 p8_6)
    (adjacent p8_6 p8_7) (adjacent p8_7 p8_6)
    (adjacent p9_6 p9_7) (adjacent p9_7 p9_6)
    (adjacent p0_7 p1_7) (adjacent p1_7 p0_7)
    (adjacent p0_7 p0_8) (adjacent p0_8 p0_7)
    (adjacent p1_7 p2_7) (adjacent p2_7 p1_7)
    (adjacent p1_7 p1_8) (adjacent p1_8 p1_7)
    (adjacent p2_7 p3_7) (adjacent p3_7 p2_7)
    (adjacent p2_7 p2_8) (adjacent p2_8 p2_7)
    (adjacent p3_7 p4_7) (adjacent p4_7 p3_7)
    (adjacent p3_7 p3_8) (adjacent p3_8 p3_7)
    (adjacent p4_7 p5_7) (adjacent p5_7 p4_7)
    (adjacent p4_7 p4_8) (adjacent p4_8 p4_7)
    (adjacent p5_7 p6_7) (adjacent p6_7 p5_7)
    (adjacent p5_7 p5_8) (adjacent p5_8 p5_7)
    (adjacent p6_7 p7_7) (adjacent p7_7 p6_7)
    (adjacent p6_7 p6_8) (adjacent p6_8 p6_7)
    (adjacent p7_7 p8_7) (adjacent p8_7 p7_7)
    (adjacent p7_7 p7_8) (adjacent p7_8 p7_7)
    (adjacent p8_7 p9_7) (adjacent p9_7 p8_7)
    (adjacent p8_7 p8_8) (adjacent p8_8 p8_7)
    (adjacent p9_7 p9_8) (adjacent p9_8 p9_7)
    (adjacent p0_8 p1_8) (adjacent p1_8 p0_8)
    (adjacent p0_8 p0_9) (adjacent p0_9 p0_8)
    (adjacent p1_8 p2_8) (adjacent p2_8 p1_8)
    (adjacent p1_8 p1_9) (adjacent p1_9 p1_8)
    (adjacent p2_8 p3_8) (adjacent p3_8 p2_8)
    (adjacent p2_8 p2_9) (adjacent p2_9 p2_8)
    (adjacent p3_8 p4_8) (adjacent p4_8 p3_8)
    (adjacent p3_8 p3_9) (adjacent p3_9 p3_8)
    (adjacent p4_8 p5_8) (adjacent p5_8 p4_8)
    (adjacent p4_8 p4_9) (adjacent p4_9 p4_8)
    (adjacent p5_8 p6_8) (adjacent p6_8 p5_8)
    (adjacent p5_8 p5_9) (adjacent p5_9 p5_8)
    (adjacent p6_8 p7_8) (adjacent p7_8 p6_8)
    (adjacent p6_8 p6_9) (adjacent p6_9 p6_8)
    (adjacent p7_8 p8_8) (adjacent p8_8 p7_8)
    (adjacent p7_8 p7_9) (adjacent p7_9 p7_8)
    (adjacent p8_8 p9_8) (adjacent p9_8 p8_8)
    (adjacent p8_8 p8_9) (adjacent p8_9 p8_8)
    (adjacent p9_8 p9_9) (adjacent p9_9 p9_8)
    (adjacent p0_9 p1_9) (adjacent p1_9 p0_9)
    (adjacent p1_9 p2_9) (adjacent p2_9 p1_9)
    (adjacent p2_9 p3_9) (adjacent p3_9 p2_9)
    (adjacent p3_9 p4_9) (adjacent p4_9 p3_9)
    (adjacent p4_9 p5_9) (adjacent p5_9 p4_9)
    (adjacent p5_9 p6_9) (adjacent p6_9 p5_9)
    (adjacent p6_9 p7_9) (adjacent p7_9 p6_9)
    (adjacent p7_9 p8_9) (adjacent p8_9 p7_9)
    (adjacent p8_9 p9_9) (adjacent p9_9 p8_9)
    (at ag1 p1_6)
    (on g1 p4_0)
    (on g2 p4_3)
    (on g3 p5_9)
    (blocked p1_1)
    (blocked p2_1)
    (blocked p3_1)
    (blocked p4_1)
    (blocked p5_1)
    (blocked p6_1)
    (blocked p7_1)
    (blocked p8_1)
    (blocked p3_6)
    (blocked p6_6)
    (blocked p3_7)
    (blocked p6_7)
    (blocked p1_8)
    (blocked p2_8)
    (blocked p3_8)
    (blocked p6_8)
    (blocked p7_8)
    (blocked p8_8)
  )
  (:goal (and (on g1 p8_6) (on g2 p8_6) (on g3 p8_6)))
)