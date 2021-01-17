# International Planning Competition 2020
The International Planning Competition (IPC) happens every ~2 years since 1998.
Its main goal is to provide a common dataset made of several planning instances written in the same language, [PDDL](https://en.wikipedia.org/wiki/Planning_Domain_Definition_Language), that are close to real world applications.
Planners compete in several tracks, searching for step-optimal (smaller plans) or satisficing (less planning time) solutions and exploiting common or uncommon description features, such as numerics and optimization.
There was no common language for Hierarchical Task Network (HTN), although the second (2000) and third (2002) IPC had tracks on 'Hand Tailored Systems'.
Most systems relied on some input format of their own, making comparisons hard to happen.
HTN IPC was proposed during [ICAPS 2019](https://www.uni-ulm.de/fileadmin/website_uni_ulm/iui.inst.090/Publikationen/2019/Behnke2019HTNIPC.pdf) to improve this situation, pushing [HDDL](http://gki.informatik.uni-freiburg.de/papers/hoeller-etal-aaai20.pdf) as the standard HTN language.

The [IPC 2020](http://gki.informatik.uni-freiburg.de/competition/) proposed two tracks: total order and partial order.
In the total order track the subtasks must be decomposed following one order, either respecting the order in which tasks were described or sorting them based on their constraints.
The partial order track contain domains in which there is more than one way to decompose tasks, which also makes possible to interleave subtasks, at the cost of complex bookkeeping.
Few domains were acyclic (subtasks that may decompose to themselves) and therefore no extra tracks happened.
The [IPC domains](../../../../../panda-planner-dev/ipc2020-domains) and [submitted domains](../../../../../panda-planner-dev/domains) are available online.

HyperTensioN participated in the total order track.
Note that the HyperTensioN used in the IPC 2020 is slightly different from the original, it is available in its [competition repository](https://gitlab.anu.edu.au/u1092535/ipc2020-competitor-4).
During the competition only HDDL_Parser, Typredicate, Pullup, Dejavu and Hyper_Compiler modules were loaded by Hype.
Hype also does not save the output of Hyper_Compiler to disk before loading it, instead it evaluates the domain and problem converted to Ruby directly, this option is still not integrated in the current repository.
The debug outputs in the planning method were commented out.
A few bugs made the competition release of HyperTensioN not able to parse Entertainment and Monroe (partially and fully observable) domains correctly, these are now fixed.
The new timings were obtained in an Intel E5500@2.8GHz with 3.25GBs of RAM, which match previous timings.
Currently, the first 5 of 12 Entertainment instances are solved in less than a second, the sixth in 42s, the seventh in 740s, and the eighth in 235s, while others will take more than 1800s.
All 20 Monroe-Fully-Observable instances are solvable, most in few seconds and the last two in 32s.
The Monroe-Partially-Observable instances are still not solvable within a 1800s time limit.
Other domains are unaffected by this change.

Domain/Planner | Total | HyperTensioN (fixed) | HyperTensioN | Lilotane | PDDL4J-TO | PDDL4J-PO | HPDL | pyHiPOP
--- | --- | --- | --- | --- | --- | --- | --- | ---
AssemblyHierarchical | 30 | 3 | 3 | **5** | 2 | 1 | 0 | 0.5
Barman-BDI | 20 | **20** | **20** | 16 | 11 | 5.5 | 10 | 0
Blocksworld-GTOHP | 30 | 16 | 16 | **22.1** | 16 | 8.5 | 6.6 | 0.5
Blocksworld-HPDDL | 30 | **30** | **30** | 1 | 0 | 0 | 0 | 0
Childsnack | 30 | **30** | **30** | 29 | 20.9 | 10.5 | 11 | 0
Depots | 30 | **24** | **24** | 23.4 | 23 | 11.4 | 11 | 0
Elevator-Learned | 147 | **147** | **147** | **147** | 2 | 1 | 5.5 | 1
Entertainment | 12 | **~5.9** | 0 | 4.6 | 4.6 | 1.5 | 0 | 0.5
Factories-simple | 20 | 3 | 3 | **4** | 0 | 0 | 0 | 0.5
Freecell-Learned | 60 | 0 | 0 | **7.7** | 0 | 0 | 0 | 0
Hiking | 30 | **25** | **25** | 21.3 | 17 | 7.3 | 0 | 0
Logistics-Learned | 80 | 22 | 22 | **43.2** | 0 | 0 | 0 | 0
Minecraft-Player | 20 | **5** | **5** | 1 | 1 | 0.5 | 1.5 | 0
Minecraft-Regular | 59 | **57.1** | **57.1** | 29.2 | 23 | 11.5 | 17.5 | 0
Monroe-Fully-Observable | 20 | ~17.7 | 0 | **20** | **20** | 9.9 | 3.2 | 0
Monroe-Partially-Observable | 20 | 0 | 0 | **20** | 1 | 0.5 | 0 | 0
Multiarm-Blocksworld | 74 | **8** | **8** | 4 | 0 | 0 | 0.5 | 0
Robot | 20 | **20** | **20** | 11 | 6 | 3 | 0 | 0.5
Rover-GTOHP | 30 | **30** | **30** | 21.3 | 27.5 | 12.8 | 15 | 3
Satellite-GTOHP | 20 | **20** | **20** | 15 | **20** | 5 | 0 | 3.5
Snake | 20 | **20** | **20** | 17.1 | **20** | 10 | 3.5 | 1
Towers | 20 | **17** | **17** | 10 | 16 | 7.5 | 5.5 | 1
Transport | **40** | **40** | **40** | 35 | 33.2 | 16.5 | 0.5 | 8.6
Woodworking | 30 | 7 | 7 | **30** | 6 | 3 | 1.5 | 2
**Total** | 892 | 567.7 | 544.1 | 537.9 | 270.2 | 126.9 | 92.8 | 22.5

The planner was executed as ``ruby --disable=all Hype.rb $DOMAINFILE $PROBLEMFILE typredicate pullup dejavu run`` to save a few milliseconds from Ruby start up time.
Due to a [limit](https://bugs.ruby-lang.org/issues/16616) in the amount of stack available to the Ruby interpreter in the Ubuntu 20.04 + Ruby 2.7 it was decided to use an older version, Ubuntu 18.04 + Ruby 2.5, to be able to solve more planning instances.
Some large planning instances require more stack, which is possible with ``export RUBY_THREAD_VM_STACK_SIZE=$(($MEMORY * 512 * 1024))``.
HyperTensioN did not exploit the seed variable provided during the competition, although it is possible that randomizing parts of the planning instance may improve timing in certain domains.

The [plan format output](http://gki.informatik.uni-freiburg.de/ipc2020/format.pdf) required by the IPC to analyze plan correctness was different from the one used by HyperTensioN.
This output format can be obtained by setting the constant ``FAST_OUTPUT = false`` in ``Hypertension.rb``, note that this adds a small overhead and modifies the API.
Some examples and tests expect the original fast output.
Plans in the IPC format can be visualized using the [HTN Plan Viewer](https://maumagnaguagno.github.io/HTN_Plan_Viewer/).

The [presented](http://gki.informatik.uni-freiburg.de/competition/results.pdf) and [fixed](http://gki.informatik.uni-freiburg.de/competition/results-fixed.pdf) results are now available, a presentation is on YouTube:

[![IPC 2020](https://img.youtube.com/vi/SSaw5YmxpaA/0.jpg)](https://www.youtube.com/watch?v=SSaw5YmxpaA "International Planning Competition (IPC) 2020 on Hierarchical Task Network (HTN) Planning: Results")