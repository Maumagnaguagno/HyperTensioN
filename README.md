# HyperTensioN [![Actions Status](https://github.com/Maumagnaguagno/HyperTensioN/workflows/build/badge.svg)](https://github.com/Maumagnaguagno/HyperTensioN/actions) [![IPC](https://img.shields.io/badge/HTN%20IPC%202020%20Total%20Order%20track-winner-D50.svg)](docs/IPC.md)
**Hierarchical Task Network planning in Ruby**

HyperTensioN is a [Hierarchical Task Network](https://en.wikipedia.org/wiki/Hierarchical_task_network) planner written in Ruby.
With hierarchical planning it is possible to describe recipes about how and when to execute actions to accomplish tasks.
These recipes describe how tasks can be decomposed into subtasks, refined until only actions remain, the plan.
This is very alike to how humans think, taking mental steps further into primitive operators.
HTN is also used as an acronym for Hypertension in medical context, therefore the name was given.
In order to support multiple [action languages](https://en.wikipedia.org/wiki/Action_language) a module named [Hype](#hype "Jump to Hype section") takes care of the conversion process.
Extended features to deal with numeric and external elements are in [HyperTensioN U](../../../HyperTensioN_U).
This project was inspired by [Pyhop] and [JSHOP].

[Download and play](../../archive/master.zip) or jump to each section to learn more:
- [**Algorithm**](#algorithm "Jump to Algorithm section"): planning algorithm explanation
- [**API**](#api "Jump to API section"): variables and methods defined by HyperTensioN
- [**Hype**](#hype "Jump to Hype section"): follow the Hype and let domain and problem be converted and executed automagically
- [**Comparison**](#comparison "Jump to Comparison section"): brief comparison with JSHOP and Pyhop
- [**Changelog**](#changelog "Jump to Changelog section"): small list of things that happened
- [**ToDo's**](#todos "Jump to ToDo's section"): small list of things to be done

More details can be found in the [docs](docs) folder:
- [**Custom Domain**](docs/Custom.md): features explained while describing a domain in Ruby
- [**Intermediate Representation**](docs/Representation.md): internal structures used by Hype
- [**International Planning Competition 2020**](docs/IPC.md): how the planner was executed and results

## Algorithm
The basic algorithm for HTN planning is quite simple and flexible, the hard part is in the structure that decomposes a hierarchy and the unification engine.
The task list (input of planning) is decomposed until nothing remains, the base of recursion, returning an empty plan.
The tail of recursion are the operator/primitive task and method/compound task cases.
Operators test if the current task (the first in the list, since it decomposes in total order) can be applied to the current state (a visible structure to all functions).
If successfully applied, the planning process continues decomposing and inserting the current task at the beginning of the plan, as it builds the plan during recursion from last to first.
Methods are decomposed into one of their several cases with a valid unification for their free variables.
Each case unified is a list of tasks, subtasks, that may require decomposition too, replacing the original method.
Only methods accept unification of free variables, although it could also unify operators (but they would not be that primitive anymore).
Methods take care of the heavy part (should the _agent_ **move** from _here_ to _there_ by **foot** ``[walking]`` or call a **cab** ``[call, enter, ride, pay, exit]``) while the operators just execute the effects when applicable.
If no decomposition is possible, failure is returned.

```Ruby
Algorithm planning(list tasks)
  return empty plan if tasks = empty
  current_task <- shift element from tasks
  if current_task is an Operator
    if applicable(current_task)
      apply(current_task)
      plan <- planning(tasks)
      return current_task . plan if plan
    end
  else if current_task is a Method
    for methods in decomposition(current_task)
      for subtasks in unification(methods)
        plan <- planning(subtasks . tasks)
        return plan if plan
      end
    end
  end
  return Failure
end
```

## API
[**Hypertension**](Hypertension.rb) is a module with 3 attributes:
- ``attr_accessor :state`` with the current state.
- ``attr_accessor :domain`` with the decomposition rules that can be applied to the operators and methods.
- ``attr_accessor :debug`` as a flag to print intermediate data during planning.

They were defined as instance variables to be mixed in other classes if needed, that is why they are not class variables.

```Ruby
# Require and use
require './Hypertension'

Hypertension.state = [...]
Hypertension.applicable?(...)
```

```Ruby
# Mix in
require './Hypertension'

class Foo < Bar
  include Hypertension

  def method(...)
    @state = [...]
    applicable?(...)
  end
end
```

Having the state and domain as separate variables also means there is no need to propagate them.
This also means that at any point one can change more than the state.
This may be useful to reorder method decompositions in the domain to modify the behavior without touching the methods or set the debug option only after a specific operator is called.
The plan is created during backtracking, which means there is no mechanism to reorder actions in the planning process, but it is possible with a variation that creates the plan during decomposition.

The methods are few and simple to use:
- ``planning(tasks, level = 0)`` receives a task list, ``[[:task1, 'term1', 'term2'], [:task2, 'term3']]``, to decompose and the nesting level to help debug.
Only call this method after domain and state were defined.
This method is called recursively until it finds an empty task list, ``[]``, then it starts to build the plan while backtracking to save CPU (avoid intermediate plan creation).
Therefore no plan actually exists before reaching an empty task list.
In case of failure, ``nil`` is returned.

- ``applicable?(precond_pos, precond_not)`` tests if the current state have all positive preconditions and not a single negative precondition. Returns ``true`` if applicable, ``false`` otherwise.
- ``apply(effect_add, effect_del)`` modifies the current state, add or remove predicates present in the lists. Returns ``true``.
- ``apply_operator(precond_pos, precond_not, effect_add, effect_del)`` applies effects if ``applicable?``. Returns ``true`` if applied, ``nil`` otherwise.
- ``generate(free, precond_pos, precond_not)`` yields all possible unifications to the free variables defined, therefore a block is needed to capture the unifications. Returns ``nil``.
- ``print_data(data)`` can be used to print task and predicate lists, useful for debug.
- ``problem(state, tasks, debug = false, ordered = true)`` simplifies the setup of a problem instance, returns the value of planning. Use problem as a template to see how to add HyperTensioN in a project.
- ``task_permutations(tasks, goal_task = nil)`` tries permutations of ``tasks`` to achieve unordered decomposition, ``goal_task`` is the final task, used by ``problem``. Returns a plan or ``nil``.

Domain operators can be defined without ``apply_operator`` and will have the return value considered.
- ``false`` or ``nil`` means the operator has failed.
- Any other value means the operator was applied with success.

Domain methods must yield a task list or are nullified, having no decomposition.

A domain and problem already described in [PDDL], [HDDL] or [JSHOP] descriptions must first be converted, which is a task for Hype.

## Hype
[**Hype**](Hype.rb) is the framework for parsers, extensions and compilers of planning descriptions.
It will save time and avoid errors during conversion of domains and problems for comparison with other planners.
Such conversion step is not new, as JSHOP2 itself compiles the description to Java code to achieve a better performance.
Hype requires domain and problem files with the correct extension type to be parsed correctly, while the output type must be specified to match a compiler.
Multiple extensions can be executed before the output happens, even repeatedly.
If no extensions and output type are provided the system default is to ``print`` what was parsed from the files and the time taken.

```
Usage:
  Hype domain problem {extensions} [output=print]

Output:
  print - print parsed data(default)
  rb    - generate Ruby files to HyperTensioN
  cpp   - generate C++ file with HyperTensioN
  pddl  - generate PDDL files
  hddl  - generate HDDL files
  jshop - generate JSHOP files
  dot   - generate DOT file
  md    - generate Markdown file
  run   - same as rb with execution
  debug - same as run with execution log
  nil   - avoid print parsed data

Extensions:
  patterns    - add methods and tasks based on operator patterns
  dummy       - add brute-force methods to operators
  dejavu      - add invisible visit operators
  wise        - warn and fix description mistakes
  macro       - optimize operator sequences
  warp        - optimize unification
  typredicate - optimize typed predicates
  pullup      - optimize structure based on preconditions
  grammar     - print hierarchical structure grammar
  complexity  - print estimated complexity of planning description
```

To convert and execute the Basic example is simple, compile once and execute multiple times the compiled output.

```Shell
cd HyperTensioN
ruby Hype.rb examples/basic/basic.jshop examples/basic/pb1.jshop rb
ruby examples/basic/pb1.jshop.rb
```

One can compile and execute in a single command with ``run``, the system compile as ``rb`` and evaluate the generated source from memory.
Use the ``debug`` flag to observe how branches are explored during planning.

```Shell
ruby Hype.rb examples/basic/basic.jshop examples/basic/pb1.jshop run
ruby Hype.rb examples/basic/basic.jshop examples/basic/pb1.jshop debug
```

If the execution displays the message ``Planning failed, try with more stack``, check for mistakes in your description.
If the message persists, increase stack size with ``RUBY_THREAD_VM_STACK_SIZE`` (Ruby), ``STACK`` (C++) or ``ulimit`` (system) to avoid overflows in large planning instances.
The interpreter loads slightly faster with the ``--disable=all`` flag.

Hype is composed of:

**Parsers**:
- [PDDL]
- [JSHOP]
- [HDDL]

**Extensions**:
- [Patterns](docs/Patterns.md) (add methods based on operator patterns, map goal state to tasks)
- [Dummy](docs/Dummy.md) (add brute-force methods that try to achieve goal predicates)
- Dejavu (add invisible visit/unvisit operators to avoid repeated decompositions)
- Wise (warn and fix description mistakes)
- Macro (optimize operator sequences to speed up decomposition)
- Warp (optimize unification with parameter splitting)
- Typredicate (optimize typed predicates)
- Pullup (optimize structure based on preconditions to avoid backtracking)
- Grammar (print domain methods as [production rules](https://en.wikipedia.org/wiki/Production_(computer_science)))
- Complexity (print domain, problem and total complexity based on amount of terms)

**Compilers**:
- Hyper (methods and tasks are unavailable for a PDDL input without extensions)
- Cyber (methods and tasks are unavailable for a PDDL input without extensions)
- [PDDL] (methods are ignored, goal must be manually converted based on tasks)
- [HDDL] (methods and tasks are unavailable for a PDDL input without extensions)
- [JSHOP] (methods and tasks are unavailable for a PDDL input without extensions)
- [Graphviz DOT](https://www.graphviz.org/) (generate a [graph](docs/Graph.md) description to be compiled into an image)
- [Markdown](https://daringfireball.net/projects/markdown/)

As any parser, the ones provided by Hype are limited in one way or another.
[PDDL] has far more features than supported by most planners and [JSHOP] has 2 different ways to define methods.
Methods may be broken into several independent blocks or in the same block without the need to check the same preconditions again.
Both cases are supported, but HyperTensioN evaluates the preconditions of each set independently while [JSHOP] only evaluates the last if the previous ones evaluated to false in the same block.
In order to copy this behavior one would need to declare the methods in the same Ruby method (losing label definition), which could decrease readability.
[JSHOP] axioms and external calls are not supported, such features are part of [HyperTensioN U](../../../HyperTensioN_U).
All [symbolic expression](https://en.wikipedia.org/wiki/S-expression) parsers can be faster with [Ichor](../../../Ichor), using ``ruby -r path/ichor Hype.rb ...`` and uncommenting their Ichor related lines.

One can always not believe the Hype and [convert descriptions manually](docs/Custom.md), following a style that achieves a better or faster solution.
Counters in methods can be used to return after a certain amount of unifications is decomposed without success.
It is possible to support [JSHOP] behavior putting several generators in one method and returning if the previous one ever unified.
Hype can do most of the boring optimizations so one can focus on the details.

### Parsers
Parsers are modules that read planning descriptions and convert the information to an [Intermediate Representation].
The basic parser is a module with two methods that fill the planning attributes:

```Ruby
module Foo_Parser
  extend self

  attr_reader :domain_name, :problem_name, :operators, :methods, :predicates, :state, :tasks, :goal_pos, :goal_not

  def parse_domain(domain_filename)
    # TODO fill attributes
  end

  def parse_problem(problem_filename)
    # TODO fill attributes
  end
end
```

With the parser completed, it needs to be connected with Hype to be selected based on the domain and problem file extensions.
Domain and problem files are expected to have the same extension to avoid incomplete data from mixed inputs.
The parser is responsible for file reading to allow uncommon, but possible, binary files.
Since parsers create structures no value is expected to be returned by ``parse_domain`` and ``parse_problem``.

### Extensions
Extensions are modules that analyze or transform planning descriptions in the [Intermediate Representation] format.
The basic extension is a module with one method to extend the attributes obtained from the parser:

```Ruby
module Extension
  extend self

  def apply(operators, methods, predicates, state, tasks, goal_pos, goal_not)
    # TODO modify attributes
  end
end
```

Extensions are supposed to be executed between the parsing and compilation phases.
More than one extension may be executed in the process, even repeatedly.
They can be used to clean, warn and fill gaps left by the original description.
Since extensions transform existing structures, the value returned by ``apply`` is undefined.

### Compilers
Compilers are modules that write planning descriptions based on the information available in the [Intermediate Representation] format.
The basic compiler is a module with two methods to compile problem and domain files to text:

```Ruby
module Bar_Compiler
  extend self

  def compile_domain(domain_name, problem_name, operators, methods, predicates, state, tasks, goal_pos, goal_not)
    # TODO return string or nil, nil generates no output file
  end

  def compile_problem(domain_name, problem_name, operators, methods, predicates, state, tasks, goal_pos, goal_not, domain_filename)
    # TODO return string or nil, nil generates no output file
  end
end
```

Unlike parsers, ``compile_domain`` and ``compile_problem`` have a choice in their output.
The first option is for uncommon outputs, they must be handled inside the methods and return ``nil``.
The second option is to return a string to be written to a common text file.
If the second option was selected the output filename is the input filename with the new extension appended, therefore ``input.pddl`` to ``jshop`` would be ``input.pddl.jshop``, so no information about the source is lost.
Any compiler have access to the parser attributes, which means one module can optimize before another compiles.
In fact this is the core idea behind Hype, be able to parse, extend and compile domains without having to worry about language support.
Future languages compatible with the [Intermediate Representation] format could be supported by just adding a new parser and compiler.
The compiler is expected to not modify the representation, use an extension to achieve such result.

## Comparison
The main advantage of HyperTensioN is to be able to define behavior in the core language, without custom classes.
Once Strings, Symbols, Arrays and Hashes are understood, the entire HyperTensioN module is just a few methods away from complete understanding.
JSHOP2 requires the user to dive into a more complex structure, while [Pyhop] is much simpler, without parsing, full backtracking and unification.
Without unification the user must ground or propagate variables by hand, and without full backtracking the methods only have one subtask sequence to explore during decomposition.
HyperTensioN is more than a planner, with parsers, extensions and compilers built around it, so that descriptions can be converted and optimized automatically.

Among the lacking features is lazy variable evaluation and interleaved/unordered execution of tasks, a feature that JSHOP2 supports and important to achieve good plans in some cases.
Unordered tasks are supported only at the problem level and are not interleaved during decomposition.

## Changelog
<details>
<summary>The changelog only includes notable changes.</summary>

- Mar 2014
  - First version based on Pyhop/JSHOP
  - Data structures modified
- Jun 2014
  - Add elements from ND_Pyhop
  - Data structures modified
  - Using previous state for state_valuation
  - Added support for minimum probability
  - Data structure simplified
  - Override state_valuation and state_copy for specific purposes
- Dec 2014
  - Forked project, probability mode only works for HyperTensioN_U
  - STRIPS style operator application instead of imperative mode
  - Backtrack support
  - Operator visibility
  - Unification
  - Plan is built after tasks solved
  - Domain and problem separated
  - Deep copy only used at operator application
- Mar 2015
  - Refactoring of generate
- Jun 2015
  - Unordered tasks with explicit goal check
- Sep 2015
  - Apply method extracted from apply_operator
- Mar 2016
  - Released version 1.0
- Nov 2017
  - Faster state duplication
- Jun 2018
  - Always restore state after backtracking
- Sep 2019
  - Ignore irrelevant predicates during compilation
- Mar 2020
  - HDDL support
- May 2020
  - Add Pullup extension
  - New state representation
- Jul 2020
  - State no longer contains rigid predicates
  - Add Typredicate extension
- Aug 2020
  - Exit code based on problem return value
  - Add Dejavu extension and cache mechanism
- Oct 2020
  - Rescue infinite recursion stack overflow
- Nov 2020
  - Released version 2.0 with new state representation
- Feb 2021
  - Released version 2.1 with new compiler optimizations
- Apr 2021
  - Cyber_Compiler is functional
- May 2021
  - Dejavu direct is no longer always active
- Jun 2021
  - Hype does not write to disk with run/debug options
- Aug 2021
  - Pack bit predicates in Cyber_Compiler
  - Rescue infinite recursion stack overflow in Cyber_Compiler
  - Fix state cache in Cyber_Compiler
- Oct 2021
  - Support equality requirement in PDDL_Compiler
- Nov 2021
  - Reuse tasks as plan in Hypertension planning
  - Avoid token collisions in Cyber_Compiler
  - Improve partial state conditions in Macro
- Feb 2022
  - Drop nil support from JSHOP
- Mar 2022
  - Add Ichor to parsers
- Apr 2022
  - Add Warp extension
  - Goal task generated by compilers
  - Consider goal task in Hypertension task_permutations
- May 2022
  - Expect same parameters for related methods in JSHOP_Parser
- Jan 2023
  - Add IPC output to Cyber_Compiler
  - Support empty goals/tasks in Patterns
- Feb 2023
  - Refactor types in PDDL/HDDL parsers
  - Parse types even when typing requirement is missing in HDDL_Parser
- Apr 2023
  - Always expect domain/problem names in PDDL/HDDL parsers
- Jul 2023
  - Add IPC output switch
- Aug 2023
  - Released version 2.2 with Cyber_Compiler
- Sep 2023
  - Support operators as tasks in Macro
  - Skip invisible operators as subtasks in Macro
- Oct 2023
  - Support unordered tasks in Macro
- Mar 2024
  - Add HDDL compiler
- Apr 2024
  - Fix interference in Pullup

</details>

## ToDo's
- Unordered subtasks
- Anytime mode
- Debugger (why is the planner not returning the expected plan?)
- More tests

[Intermediate Representation]: docs/Representation.md
[PDDL]: https://en.wikipedia.org/wiki/Planning_Domain_Definition_Language "PDDL at Wikipedia"
[JSHOP]: https://www.cs.umd.edu/projects/shop/description.html "SHOP/JSHOP project page"
[HDDL]: https://gki.informatik.uni-freiburg.de/papers/hoeller-etal-aaai20.pdf "HDDL paper"
[Pyhop]: https://bitbucket.org/dananau/pyhop "Pyhop project page"