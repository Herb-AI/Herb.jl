# Installation Guide

Before installing Herb.jl, ensure that you have a running Julia distribution installed (Julia version 1.7 and above were tested). 

Thanks to Julia's package management, installing Herb.jl is very straighforward. 
Activate the default Julia REPL using

```shell
julia
```

or from within one of your projects using

```shell
julia --project=.
```

From the Julia REPL run 
```julia
]
add Herb
```

or instead running

```julia
import Pkg
Pkg.add("Herb")
```

which will both install all dependencies automatically.

And just like this you are done! Welcome to Herb.jl!

