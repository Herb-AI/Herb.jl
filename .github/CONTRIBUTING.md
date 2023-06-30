# Contributing to Herb.jl

Thank you for considering contributing to Herb.jl! We appreciate your interest in helping to improve the capabilities of our program synthesis library. This document provides guidelines for contributing to the project. Please take a moment to review these guidelines before making your contribution.

## Table of Contents

- [Reporting Issues](#reporting-issues)
- [Contributing Code](#contributing-code)
- [Branching and Workflow](#branching-and-workflow)
- [Code Style and Guidelines](#code-style-and-guidelines)
- [Testing](#testing)
- [Documentation](#documentation)
- [Pull Requests](#pull-requests)
- [Code Review](#code-review)
- [Licensing](#licensing)
- [Code of Conduct](#code-of-conduct)
- [Contact](#contact)

## Reporting Issues

If you encounter any issues or bugs in Herb.jl, please report them using the GitHub issue tracker. Before submitting a new issue, please search existing issues to ensure it hasn't already been reported. When reporting an issue, please provide detailed information, including steps to reproduce the problem, relevant code samples, and any error messages received.

## Contributing Code

We welcome contributions to Herb.jl! If you'd like to contribute code changes, new features, or bug fixes, please follow these steps:

1. Set up the development environment by following the instructions in the README.md file.
2. Create a new branch for your contribution using a descriptive name for the respective repository.
3. Make your changes, ensuring that your code adheres to the code style and guidelines outlined below.
4. Write tests to cover your changes and ensure existing tests pass.
5. Update the documentation if necessary.
6. Commit your changes with a clear and concise commit message.
7. Push your branch to your forked repository.
8. Submit a pull request (PR) to the main Herb.jl repository, clearly describing your changes and referencing any related issues (see [Pull requests](#pull-requests))

## Branching and Workflow

Herb.jl follows the GitFlow branching model. Please create your feature branches from the `develop` branch and submit your pull requests to the `develop` branch as well. The `master` branch contains the stable, production-ready code.

## Code Style and Guidelines

We strive to maintain a consistent coding style throughout the Herb.jl project. When contributing code, please adhere to the following guidelines:

- Use meaningful and descriptive variable and function names.
- Follow the Julia style guide (https://docs.julialang.org/en/v1/manual/style-guide/).
- Use proper indentation and whitespace for readability.
- Document your code using Julia docstrings.

## Testing

Herb.jl uses a comprehensive test suite to ensure the correctness and reliability of its functionality. When contributing code changes, please make sure to write tests for new features or modifications and ensure that all existing tests pass. To run the tests, follow the instructions in the README.md file.

## Documentation

Clear and comprehensive documentation is essential for the usability and maintainability of Herb.jl. If you make changes that affect the library's behavior or functionality, please update the documentation accordingly. This includes updating interface documentation, examples, and any other relevant sections. Documentation is automatically generated from doc-strings around the respective functions using `Documenter.jl`. Therefore doc-strings have to be formatted as follows:

- Start with the signature, indented with a long tab
- Describe functionality, inputs and output concisely and clear. Refer to usages if needed

An example can be found below:

```
"""
	rulesoftype(node::RuleNode, grammar::Grammar, ruletype::Symbol)

Returns every rule of nonterminal symbol `ruletype` that is also used in the [`AbstractRuleNode`](@ref) tree.
"""
function ...
```

## Pull Requests

To submit your code changes, please create a pull request (PR) on GitHub. Ensure that your PR includes the following:

- A clear and concise description of your changes.
- References to any related issues.
- Properly formatted and tested code.
- Updated documentation if applicable.

## Code Review

Code review is an important part of the contribution process. All PRs will be reviewed by project maintainers or contributors. During the review, feedback may be provided to suggest improvements or address any issues. We appreciate your patience and collaboration during this process.

## Licensing

By contributing to Herb.jl, you agree that your contributions will be licensed under the project's license. Please see the LICENSE file for details.

## Code of Conduct

Contributors to Herb.jl are expected to adhere to the project's code of conduct, which promotes a friendly, inclusive, and respectful community. Instances of unacceptable behavior should be reported to the project maintainers.

## Contact

If you have any questions, concerns, or suggestions regarding Herb.jl or the contribution guidelines, please feel free to reach out to the project maintainers or the community via the GitHub issue tracker.

Thank you for your contributions!
