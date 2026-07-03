# Garden
[![Build Status](https://github.com/Herb-AI/Garden.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/Herb-AI/Garden.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/Herb-AI/Garden.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/Herb-AI/Garden.jl)
[![PkgEval](https://JuliaCI.github.io/NanosoldierReports/pkgeval_badges/G/Garden.svg)](https://JuliaCI.github.io/NanosoldierReports/pkgeval_badges/G/Garden.html)
[![Aqua](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)


<table>
  <tr>
    <td width="260" valign="top">
      <img src="https://github.com/user-attachments/assets/1323efc7-a708-45f4-bb26-509fbcbf7f93" alt="Cropped Image" width="220"/>
    </td>
    <td valign="top">
      <strong>Garden.jl</strong><br/>
      A collection of small, focused examples showing how to use <a href="https://herb-ai.github.io/Herb.jl/dev/">Herb.jl</a>.
      Use the examples as a starting point for your own custom synthesizers or re-implementations.
    </td>
  </tr>
</table>

## Structure

Each synthesizer has its own dedicated folder with the suggested structure:

- `method.jl` — Main functionality for the synthesizer. Helper functions may go in other files.
- `README.md` — Description of the synthesizer, what it does, inputs, and how to run it.
- `ref.bib` — Bibliography or references related to the implementation.
- `test/` - Add a dedicated file with tests for each synthesizer to the test folder.


