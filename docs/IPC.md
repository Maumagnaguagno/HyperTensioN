# International Planning Competition 2020
The International Planning Competition (IPC) happens every ~2 years since 1998.
Its main goal is to provide a common dataset made of several planning instances written in the same language, [PDDL](https://en.wikipedia.org/wiki/Planning_Domain_Definition_Language), that are close to real world applications.
Planners compete in several tracks, searching for step-optimal (smaller plans) or satisficing (less planning time) solutions and exploiting common or uncommon description features, such as numerics and optimization.
There was no common language for Hierarchical Task Network (HTN), althought the second (2000) and third (2002) IPC had tracks on 'Hand Tailored Systems'.
Most systems relied on some input format of their own, making comparisons hard to happen.
HTN IPC was proposed during [ICAPS 2019](https://www.uni-ulm.de/fileadmin/website_uni_ulm/iui.inst.090/Publikationen/2019/Behnke2019HTNIPC.pdf) to improve this situation, pushing [HDDL](http://gki.informatik.uni-freiburg.de/papers/hoeller-etal-aaai20.pdf) as the default HTN language.

The [IPC 2020](http://gki.informatik.uni-freiburg.de/competition/) proposed two tracks: total order and partial order.
In the total order track the subtasks must be decomposed following one order, either respecting the order in which tasks were described or sorting them based on their constraints.
The partial order track contain domains in which there is more than one way to decompose tasks, which also makes possible to interleave subtasks, at the cost of complex bookkeeping.
Few domains were acyclic (subtasks that may decompose to themselves) and therefore no extra tracks happened.
You can see the [IPC domains](../../../../../panda-planner-dev/ipc2020-domains) and [submitted domains](../../../../../panda-planner-dev/domains) online.

HyperTensioN participated in the total order track.
Note that the HyperTensioN used in the IPC 2020 is slighly different from the original, it is available in its [competition repository](https://gitlab.anu.edu.au/u1092535/ipc2020-competitor-4).
During the competition only HDDL_Parser, Typredicate, Pullup, Dejavu and Hyper_Compiler modules were loaded by Hype.
Hype also does not save the output of Hyper_Compiler to disk before loading it, instead it evaluates the domain and problem converted to Ruby directly, this option is still not available in the current repository.
The debug outputs in the planning method were commented out.
A few bugs made HyperTensioN not able to solve Ententainment and Monroe domains, these bugs happened during HDDL parsing and are now fixed.
The planner was executed as ``ruby --disable=all Hype.rb $DOMAINFILE $PROBLEMFILE typredicate pullup dejavu run`` to save a few milliseconds from Ruby start up time.
Due to a [limit](https://bugs.ruby-lang.org/issues/16616) in the amount of stack available to the Ruby interpreter in the Ubuntu 20.04 + Ruby 2.7 we decided to use an older version, Ubuntu 18.04 + Ruby 2.5, to be able to solve more planning instances.
Some large planning instances require more stack than the default available, requiring ``export RUBY_THREAD_VM_STACK_SIZE=$(($MEMORY * 512 * 1024))``.
HyperTensioN did not exploit the seed variable provided during the competition, although it is possible that randomizing parts of the planning instance may improve timing in certain domains.

The [plan format output](http://gki.informatik.uni-freiburg.de/ipc2020/format.pdf) is different from the one used by the current HyperTensioN, the IPC required its own format to analyze plan correctness.
You can visualize the plans in the IPC format using [this online tool](https://maumagnaguagno.github.io/HTN_Plan_Viewer/).
Due to a small overhead and difference in the API this format is currently not the default output, but can be turned on by setting the constant ``FAST_OUTPUT = false`` in ``Hypertension.rb``.
Note that some examples and tests expect the fast output.

The [presented](http://gki.informatik.uni-freiburg.de/competition/results.pdf) and [fixed](http://gki.informatik.uni-freiburg.de/competition/results-fixed.pdf) results are now available.
You can see the results presentation on YouTube:

[![IPC 2020](https://img.youtube.com/vi/SSaw5YmxpaA/0.jpg)](https://www.youtube.com/watch?v=SSaw5YmxpaA "International Planning Competition (IPC) 2020 on Hierarchical Task Network (HTN) Planning: Results")