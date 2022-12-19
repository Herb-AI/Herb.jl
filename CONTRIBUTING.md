# Herb development guidelines
Below are some guidelines for working on the Herb Program Synthesis framework. These rules are flexible, they can be updated when necessary.

## Git
- Don't push directly to the main branch
- To add new functionality, create a new branch from the main branch and give it a meaningful name. Once everything works, create a merge request for moving the code back to the main branch and ideally have it reviewed by someone else.
- Make sure that the code in the main branch works and is compatible with the main branches from other repositories
- Create issues and keep them up-to-date

## Code
- Add *useful* comments to your code
- Document functions using [docstrings](https://docs.julialang.org/en/v1/manual/documentation/#Writing-Documentation) 
- Give clear names to functions, variables and structures 
- Have a quick look at the [Julia style guide](https://docs.julialang.org/en/v1/manual/style-guide/). Some important things to highlight:
	- Append `!` to names of functions that modify their arguments
	- Module names are `CamelCase` 
	- Function names are generally `lowercase`
