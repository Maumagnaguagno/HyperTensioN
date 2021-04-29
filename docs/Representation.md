# Intermediate Representation
Hype is able to parse from and compile to different languages, with the parsed language usually being easier to describe planning elements while the compiled language deals with a different set of planning elements or computer details.
Instead of creating one converter for each input-output pair, such as parseA-CompileB, a more modular design approach with parser and compiler completely independent was selected.
The only thing that both parts must share is a [common representation](https://en.wikipedia.org/wiki/Intermediate_language).
All elements from the languages involved must be able to be represented or inferred from the selected common representation.
The elements considered for planning are:
- [**Domain and problem names**](#domain-and-problem-names)
- [**Operators**](#operators)
- [**Methods**](#methods)
- [**Predicates**](#predicates)
- [**States, Goals and Tasks**](#states-goals-and-tasks)

## Domain and Problem names
Domain and problem names are Strings representing the scenario and require no modification.
Usually domains and problems are limited to alphanumeric, hyphen and underline characters, without any blank spaces.
Names are used only to validate that problem and domain are related to each other, so that when combined a valid planning instance can be obtained.

```Ruby
@domain_name  = 'rescue'
@problem_name = 'pb1'
```

## Operators
Compare the following PDDL action and JSHOP operator:

```Lisp
(:action move
  :parameters (?agent ?from ?to)
  :precondition (and
    (at ?agent ?from)
    (adjacent ?from ?to)
    (not (blocked ?to))
  )
  :effect (and
    (at ?agent ?to)
    (not (at ?agent ?from))
  )
)
```

```Lisp
(:operator (!move ?agent ?from ?to)
  ; Positive and negative preconditions
  (
    (at ?agent ?from)
    (adjacent ?from ?to)
    (not (blocked ?to))
  )
  ((at ?agent ?from)) ; Del effects
  ((at ?agent ?to))   ; Add effects
)
```

They represent the same data, with PDDL giving more tokens to clarify what each field represents.
Preconditions and effects are conjunctions of predicates and more complex expressions are yet to be supported.
The following Ruby code is the intermediate representation obtained by one of the above representations.

```Ruby
@operators = [
  ['move', ['?agent', '?from', '?to'],
    # Positive preconditions
    [['at', '?agent', '?from'], ['adjacent', '?from', '?to']],
    # Negative preconditions
    [['blocked', '?to']],
    # Add effects
    [['at', '?agent', '?to']],
    # Del effects
    [['at', '?agent', '?from']]
  ]
]
```

Some elements may be simplified by the parser to make the common representation compatible with any language.
PDDL types can be downgraded to positive preconditions in the domain and added to the initial state in the problem.
Disjunctions and conditionals would require an AST or an expansion to cover each case.
Quantifiers require more work and are currently not supported by the intermediate representation.
Since Arrays are being used, it is possible to add more data beyond the first 6 positions.
Until then the [experimental](../examples/experiments) ideas are being tested in pure Ruby.

## Methods
Sometimes one wants to apply specific actions in a certain order to accomplish a task.
Those tasks are made from methods and act as domain knowledge to be exploited by a HTN planner.
The following method is the swap from the [basic JSHOP domain](../examples/basic/basic.jshop) example, it contains two possible cases:

```Lisp
(:method (swap ?x ?y)
  ; have X, but no Y
  ((have ?x) (not (have ?y)))
  ((!drop ?x) (!pickup ?y))
  ; have Y, but no X
  ((have ?y) (not (have ?x)))
  ((!drop ?y) (!pickup ?x))
)
```

Preconditions are a conjunction of predicates and more complex expressions are yet to be supported, while subtasks are always considered to be ordered.
And is represented by:

```Ruby
@methods = [
  ['swap', ['?x', '?y'],
    # First case becomes 'swap_0' because no label was found in JSHOP
    ['swap_0',
      # Free variables
      [],
      # Positive preconditions
      [['have', '?x']],
      # Negative preconditions
      [['have', '?y']],
      # Subtasks
      [
        ['drop', '?x'],
        ['pickup', '?y']
      ]
    ],
    # Second case becomes 'swap_1' because no label was found in JSHOP
    ['swap_1',
      # Free variables
      [],
      # Positive preconditions
      [['have', '?y']],
      # Negative preconditions
      [['have', '?x']],
      # Subtasks
      [
        ['drop', '?y'],
        ['pickup', '?x']
      ]
    ]
  ]
]
```

## Predicates
Predicates are partitioned in three types to both planners and compilers to decide which informations are important.
Predicates that appear in effects are considered fluent while predicates that appear only in preconditions are considered rigid.
Other predicates are considered irrelevant and may be pruned without any problem.
In order to obtain this knowledge a Hash maps predicate name to ``true``, if fluent, or ``false``, if rigid.
Irrelevant predicates are not stored.
Note that frozen predicate strings avoid key duplication by the Hash implementation.

```Ruby
pre_fluent     = ['have',   '?x']
pre_rigid      = ['object', '?x']
pre_irrelevant = ['cookie', '?y']

@predicates = {
  pre_fluent.first.freeze => true,
  pre_rigid.first.freeze => false
}
```

## States, Goals and Tasks
The state represents how the objects are in the world in a moment.
Anything not declared here is considered false, based on the [closed-world assumption](https://en.wikipedia.org/wiki/Closed-world_assumption).
Usually the initial and goal states are described in a classical planning problem, while initial state and tasks are described for HTN planning.
Compare the following PDDL and JSHOP problem files:

```Lisp
(define (problem pb3)
  (:domain basic)
  (:requirements :strips :negative-preconditions)
  (:objects
    kiwi banjo
  )
  (:init
    (have kiwi)
  )
  (:goal (and
    (not (have kiwi))
    (have banjo)
  ))
)
```

```Lisp
(defproblem problem basic
  ; Initial state
  ((have kiwi))
  ; Tasks
  ((swap banjo kiwi))
)
```

JSHOP has an implicit goal, while PDDL has an explicit goal, which is reached by the application of the tasks (in an ordered or unordered fashion) it always maps to empty sets.
The state is more compactly represented by a Hash ``{'predicate' => [['term1', 'term2'], ['other_term1', 'other_term2'], ...], 'other_predicate' => [...], ...}``, allowing simpler operations to obtain terms of a specific predicate.
Note that this state representation used by the parsing, extension and compiler modules differ from the one generated by the [Hyper_Compiler](../compilers/Hyper_Compiler.rb), which groups fluent predicates in a state Array ``HAVE = 0; [ [[:kiwi]] ]`` while keeping static predicates separate to speed-up state operations.
The first element in the task list is a boolean that represents if the tasks are going to be decomposed in an orderly fashion or not.

```Ruby
# PDDL
@state = {'have' => [['kiwi']]}
@goal_pos = [ ['have', 'banjo'] ]
@goal_not = [ ['have', 'kiwi'] ]
@tasks = [] # No tasks

# JSHOP
@state = {'have' => [['kiwi']]}
@goal_pos = [] # No goal state
@goal_not = [] # No goal state
@tasks = [true, ['swap', 'banjo', 'kiwi'] ] # Ordered tasks
```