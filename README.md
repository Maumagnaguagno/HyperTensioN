# HyperTensioN
HTN planner in Ruby

Hypertension is an Hierarchical Task Network Planner written in Ruby, which means you have to describe how tasks can be accomplished using methods to achieve a plan. This is very alike how humans think, taking mental steps further into primitive actions. When all actions are satisfied the plan found is a valid one.

The current version has most of its algorithm inspired by PyHop, with backtracking and unification added.

# How it works

ToDo PUT ALGORITHM HERE

The idea is to **include** Hypertension in your domain module to define the methods and primitive actions while having the different problems for this domain in a separate file or generated during run-time. Since Hypertension uses metaprogramming, you need to specify which Ruby methods are used and how. The other way to define this would be the unit test way, using method names as implicit information, but that does not solve the problem for HTN methods. HTN methods are able to decompose in several ways, it is wiser to split then in different Ruby methods.

### Domain example

ToDo PUT ROBBY EXAMPLE HERE

### Problem

ToDo PUT ROBBY EXAMPLE HERE

### Advantages

ToDo

# ToDoS
- Complete the README
