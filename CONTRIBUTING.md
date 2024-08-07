# Contributor Guide

Thank you for contributing to Herb.jl. Below are some guidelines on how you can do so.

## Overview Herb repositories

The Herb.jl framework for program synthesis comprises multiple sub-packages with the following functionality:
- HerbCore.jl: Core functionality of the program synthesis library, including the representation and manipulation of expression trees, and abstract types for constraints and grammars.
- HerbGrammar.jl: Declaring grammars.
- HerbSpecification.jl: Specifying the program synthesis problems. Currently, only the input-output examples are supported, but we are working on other specification types (formal specifications, traces, rewards...). 
- HerbSearch.jl: Search procedures for finding solution programs to a program synthesis problem.
- HerbInterpret.jl: Handling the interpretation of (candidate) programs, supporting arbitrary Julia expressions or other interpretors with provided evaluation functions.
- HerbConstraints.jl: Formulating, representing and using contraints.
- HerbBenchmarks.jl: a collection of problems for testing program synthesisers. We are collecting commonly used problems, standardising them, as finding new ones.
- Garden.jl: complete implementations of known synthesisers. This repository intends to set the standard baselines to use in research, as well as support users that only wish to apply program synthesisers to their problems.

## Reporting Bugs

If you find a bug, open a new issue in the appropriate repo. Please provide some details about the bug, including 
- a description of the problem.
- a minimal example to reproduce the problem (by copy + paste).
- relevant error messages and logs. 

## Suggesting Features

We encourage and welcome suggestions for new features. Please open a new issue and describe the desired feature in as much detail as you can, including an example of how you would like to use it. 

## Contributing Code

### Workflow

To contribute code, please follow these steps:
1. Fork the repository.
2. Clone your fork to your local machine.
3. Create a new branch (with a descriptive name) for your bug fix or feature. 
4. Make changes in the new branch.
5. Test and document your code. 
6. Push your changes to your fork of the repo.
7. Open a PR from the appropriate branch of your fork to the `dev` branch of the original repo.

### Code quality guidelines

- **Testing:** Make sure your code is well-tested, i.e., that you add new tests for your code changes and that all existing tests still pass.
- **Documentation:** Please update or add documentation as necessary. Follow the Julia guidelines for [writing documentation](https://docs.julialang.org/en/v1/manual/documentation/#Writing-Documentation).
- Please follow the [Julia style guide](https://docs.julialang.org/en/v1/manual/style-guide/).

### Code changes to multiple sub-packages

If the code you're developing requires changes to more than one Herb.jl sub-package, see [this description](https://github.com/Herb-AI/) on how to locally change to a specific version (branch) of a package. 

## Don't know how to contribute?

Check the open issues in the individual repositories. We maintain a list of bugs and desired developments for each of our repositories.

Have a program synthesiser you wish to be included? Implement it in [Garden](https://github.com/Herb-AI/Garden.jl), following the workflow above! If you are uncertain about the structure, please contact us.

## Ongoing developments

We are currently focusing on the following functionality:
 - Machine learning-guided program synthesis
 - Refactoring approach a la DreamCoder and KNORF
 - Divide & conquer approaches a la EUSolver
 - New benchmarks.
 
 Do contact us if you want to help! 