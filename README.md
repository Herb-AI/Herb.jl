[![Build Status](https://github.com/Herb-AI/Herb.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/Herb-AI/Herb.jl/actions/workflows/CI.yml?query=branch%3Amaster)
[![Nightly](https://github.com/Herb-AI/Herb.jl/workflows/Nightly/badge.svg)](https://github.com/Herb-AI/Herb.jl/actions/workflows/nightly.yml)
[![Dev-Docs](https://img.shields.io/badge/docs-latest-blue.svg)](https://Herb-AI.github.io/Herb.jl/dev)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.15746953.svg)](https://doi.org/10.5281/zenodo.15746953)

# Herb.jl
*A library for defining and efficiently solving program synthesis tasks in Julia.*

## Introduction
When writing research software we almost always investigate highly specific properties or algorithms of our domain, leading to us building the tools from scratch over and over again. The very same holds for the field of program synthesis: Tools are hard to run, benchmarks are hard to get and prepare, and its hard to adapt our existing code to a novel idea.

Herb.jl will take care of this for you and helps you defining, solving and extending your program synthesis problems.

Herb.jl provides...
- a unified and universal framework for program synthesis
- Herb.jl allows you to describe all sorts of program synthesis problems using context-free grammars
- a number of state-of-the-art benchmarks and solvers already implemented and usable out-of-the-box

Herb.jl's sub-packages provide fast and easily extendable implementations of
- various static and dynamic search strategies,
- learning search strategies, sampling techniques and more,
- constraint formulation and propagation,
- easy grammar formulation and usage,
- wide-range of usable program interpreters and languages + the possibility to use your own, and
- efficient data formulation.

## Getting started
Please check out our [tutorial](https://herb-ai.github.io/Herb.jl/dev/install/).
Also check out recent projects and events on our [website](https://herb-ai.github.io).

## Conventions

## Documentation
The entire documentation is available at [https://herb-ai.github.io/Herb.jl/dev/install/](https://herb-ai.github.io/Herb.jl/dev/install/).

