# `HerbInterpret` Benchmarks

This directory contains a small benchmark suite for `HerbInterpret` to protect against performance regressions.

The suite is constructed in `benchmarks.jl` using [`BenchmarkTools.jl`](https://juliaci.github.io/BenchmarkTools.jl/stable/).

The suite is assigned to a constant, `SUITE`. Running `benchmarks.jl` does *not* run the benchmark, that is the job of tools like [`AirspeedVelocity`](https://juliahub.com/ui/Packages/General/AirspeedVelocity) and [`PkgBenchmark`](https://juliahub.com/ui/Packages/General/PkgBenchmark). These are tools you might want to install in your global Julia environment. With `AirspeedVelocity`, you can run the benchmarks like this:

```sh
benchpkg HerbInterpret --rev=v0.1.7,dirty --path=.
```

where the path points to the base directory of `HerbInterpret.jl` (meaning it should be `--path=..` if you're in the `benchmark` directory).