# Documentation of Herb.jl

This documentation was created using [Documenter.jl](https://documenter.juliadocs.org/stable/man/guide/). 

## Writing documentation

The majority of the documentation of automatically generated from the respective docstrings of each sub-package. 
There are some pages that were added manually and can be edited likewise. New pages can 1. easily be written in markdown and 2. added to the site-tree by editing `docs/make.jl`. 

## Tutorial notebooks
The tutorials are written as Pluto notebooks and can be found in `docs/src/tutorials/`. To ensure that both CI builds and manual execution use the same dependencies as defined in `docs/Project.toml`, each tutorial notebook should include the following cell at the top:
```julia
begin
    import Pkg
    Pkg.activate(Base.current_project())
    Pkg.instantiate()
    
    # Your package imports ...
end
```
Note that this disables Pluto's built-in package manager.

## Compiling the documentation
Compiling is automatically triggered whenever pushing to this branch. 

If you want to run the documentation locally run `julia --project=. make.jl` from this directory.
Once built successfully, the documentation is generated in the directory `docs/build`. You can preview it by either opening `docs/build/index.html` in a browser,
or by using `LiveServer`:
```
julia --project=. -e 'using Pkg; Pkg.add("LiveServer"); using LiveServer; serve(dir="build")'  
```
The documentation will be available at http://localhost:8000.

## Help!

If help is needed reach out to [THinnerichs](https://github.com/thinnerichs).

#### Note
The `other` folder contains some old material that is not hosted on our website. 
