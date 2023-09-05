[![Build Status](https://github.com/Herb-AI/Herb.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/Herb-AI/Herb.jl/actions/workflows/CI.yml?query=branch%3Amaster)
[![Dev-Docs](https://img.shields.io/badge/docs-latest-blue.svg)](https://Herb-AI.github.io/Herb.jl/dev)


# Herb.jl
Welcome to `Herb.jl`, a program synthesis library using the Julia programming language. 

## Introduction
The task of program synthesis considers automatic generation of programs with respect to a higher-order specification. 
This involves searching through a space of possible programs, that are usually described by a domain specific language (DSL), determining possible derivations and expansions and expressed by a grammar (See [HerbGrammar.jl](https://github.com/Herb-AI/HerbGrammar.jl)). Specifications may be expressed in a variety of forms such as input-output examples, logical formulas, or natural language descriptions (See [HerbData.jl](https://github.com/Herb-AI/HerbData.jl)). 

There are two ways of narrowing down this enormous search space: First, one may use constraints to assist the search itself by pruning the exploration rendundant, useless or impossible sub-programs (See [HerbConstraints.jl](https://github.com/Herb-AI/HerbConstraints.jl)). 
Second, one may use guiding heuristics and different search strategies to suitable programs (See [HerbSearch](https://github.com/Herb-AI/HerbSearch.jl)) or learn to guide the search itself (See [HerbLearn](yet_to_be_published)).

## Getting started
To get started with our library, please have a look at our introductory examples in [HerbExamples](https://github.com/Herb-AI/HerbExamples.jl). 

## Library structure and compartments

## Conventions

## Documentation

