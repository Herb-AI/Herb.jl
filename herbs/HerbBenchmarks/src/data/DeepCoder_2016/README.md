# DeepCoder Benchmark

The DeepCoder specializes in functional programs that manipulate lists. 
Each problem is written as a set of input-output examples.

The DeepCoder benchmark is derived from Balog et al. (2016) using the setup from Neo (Feng et al., 2018), as the evaluation benchmarks are not publicly available.
Neo thus generated 100 benchmarks following this workflow:

> We enumerate DSL programs with
> at least 5 components and randomly generate inputs and the
> corresponding output. This procedure is repeated for a fixed
> number of times until we either obtain 5 valid input-output
> examples or no examples have been found within the iter-
> ation limit. In the latter case, we restart this process and
> randomly search for a different program.

See
> Balog, M., Gaunt, A. L., Brockschmidt, M., Nowozin, S., & Tarlow, D. (2016). Deepcoder: Learning to write programs. arXiv preprint arXiv:1611.01989.
and
> Feng, Y., Martins, R., Bastani, O., & Dillig, I. (2018). Program synthesis using conflict-driven learning. ACM SIGPLAN Notices, 53(4), 420-435.

