# Robby
## Predicates
- robot: constant
- hallway: constant
- room: constant
- at: mutable
- connected: constant
- location: constant
- beacon: constant
- in: constant
- reported: mutable
- visited_at: mutable

## Operators
Enter | ?bot ?source ?destination
--- | ---
***Preconditions*** | ***Effects***
(robot ?bot) |
(hallway ?source) |
(room ?destination) |
(at ?bot ?source) | **not** (at ?bot ?source)
(connected ?source ?destination) |
**not** (at ?bot ?destination) | (at ?bot ?destination)

Exit | ?bot ?source ?destination
--- | ---
***Preconditions*** | ***Effects***
(robot ?bot) |
(room ?source) |
(hallway ?destination) |
(at ?bot ?source) | **not** (at ?bot ?source)
(connected ?source ?destination) |
**not** (at ?bot ?destination) | (at ?bot ?destination)

Move | ?bot ?source ?destination
--- | ---
***Preconditions*** | ***Effects***
(robot ?bot) |
(hallway ?source) |
(hallway ?destination) |
(at ?bot ?source) | **not** (at ?bot ?source)
(connected ?source ?destination) |
**not** (at ?bot ?destination) | (at ?bot ?destination)

Report | ?bot ?source ?thing
--- | ---
***Preconditions*** | ***Effects***
(robot ?bot) |
(location ?source) |
(beacon ?thing) |
(at ?bot ?source) |
(in ?thing ?source) |
**not** (reported ?bot ?thing) | (reported ?bot ?thing)

Invisible_visit_at | ?bot ?source
--- | ---
***Preconditions*** | ***Effects***
| (visited_at ?bot ?source)

Invisible_unvisit_at | ?bot ?source
--- | ---
***Preconditions*** | ***Effects***
| **not** (visited_at ?bot ?source)

## Methods
**Swap_at_until_at(?bot ?source)**
- swap_at_base_at(?bot ?source)
  - Preconditions:
    - (at ?bot ?source)
  - Subtasks:
- swap_at_until_at_using_enter(?bot ?source)
  - Preconditions:
    - (at ?bot ?current)
    - (connected ?current ?intermediate)
    - **not** (at ?bot ?source)
    - **not** (visited_at ?bot ?intermediate)
  - Subtasks:
    - (enter ?bot ?current ?intermediate)
    - (invisible_visit_at ?bot ?current)
    - (swap_at_until_at ?bot ?source)
    - (invisible_unvisit_at ?bot ?current)
- swap_at_until_at_using_exit(?bot ?source)
  - Preconditions:
    - (at ?bot ?current)
    - (connected ?current ?intermediate)
    - **not** (at ?bot ?source)
    - **not** (visited_at ?bot ?intermediate)
  - Subtasks:
    - (exit ?bot ?current ?intermediate)
    - (invisible_visit_at ?bot ?current)
    - (swap_at_until_at ?bot ?source)
    - (invisible_unvisit_at ?bot ?current)
- swap_at_until_at_using_move(?bot ?source)
  - Preconditions:
    - (at ?bot ?current)
    - (connected ?current ?intermediate)
    - **not** (at ?bot ?source)
    - **not** (visited_at ?bot ?intermediate)
  - Subtasks:
    - (move ?bot ?current ?intermediate)
    - (invisible_visit_at ?bot ?current)
    - (swap_at_until_at ?bot ?source)
    - (invisible_unvisit_at ?bot ?current)

**Dependency_swap_at_until_at_before_report(?bot ?source ?thing)**
- dependency_swap_at_until_at_before_report_satisfied(?bot ?source ?thing)
  - Preconditions:
    - (robot ?bot)
    - (location ?source)
    - (beacon ?thing)
    - (in ?thing ?source)
    - (at ?bot ?source)
  - Subtasks:
    - (report ?bot ?source ?thing)
- dependency_swap_at_until_at_before_report_unsatisfied(?bot ?source ?thing)
  - Preconditions:
    - (robot ?bot)
    - (location ?source)
    - (beacon ?thing)
    - (in ?thing ?source)
    - **not** (at ?bot ?source)
  - Subtasks:
    - (swap_at_until_at ?bot ?source)
    - (report ?bot ?source ?thing)

**Unify_dependency_swap_at_until_at_before_report(?bot ?thing)**
- unify_dependency_swap_at_until_at_before_report(?bot ?thing)
  - Preconditions:
    - (robot ?bot)
    - (location ?source)
    - (beacon ?thing)
    - (in ?thing ?source)
  - Subtasks:
    - (dependency_swap_at_until_at_before_report ?bot ?source ?thing)
