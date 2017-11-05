(define (domain dependency)
  (:requirements :strips :typing :negative-preconditions)
  (:types agent object)
  (:predicates (have ?a ?x) (got_money ?a) (happy ?a))

  (:action work
    :parameters (?a - agent)
    :precondition (not (got_money ?a))
    :effect (and (not (happy ?a)) (got_money ?a))
  )

  (:action buy
    :parameters (?a - agent ?x - object)
    :precondition (and (got_money ?a) (not (have ?a ?x)))
    :effect (and (not (got_money ?a)) (have ?a ?x))
  )

  (:action give
    :parameters (?a ?b - agent ?x - object)
    :precondition (and (have ?a ?x) (not (have ?b ?x)))
    :effect (and (not (have ?a ?x)) (have ?b ?x) (happy ?b))
  )
)