# transitorios-cabos
Conjunto de códigos para simulação de transitórios eletromagnéticos em cabos.

This repository is a Julia package. Load it with `using TransitoriosCabos`;
`src/TransitoriosCabos.jl` defines the library and does not run a simulation by itself.
The setup below is tested with Julia **1.12.6**.

## Figure 5 impulse benchmark (Gudmundsdottir / Gustavsen, 2011)

Run the 7.625 km, nine-segment cross-bonded cable with an impulse applied to
phase 1, five 500 Ω core terminations and all terminal sheaths grounded:

```sh
julia --project=. examples/gustavsen2011.jl
```

This saves plots and CSV/NPZ waveforms in `output/gustavsen2011/`.
See [the extracted data and case documentation](examples/gustavsen2011/README.md)
for the cable dimensions, bonding network, configuration and source limitations.
Defaults use the paper's 4.08 kV, 1.2/50 μs impulse and an explicitly assumed
soil resistivity of 100 Ω·m. This reconstructs the test circuit; measured
waveform samples are not supplied in the paper.

## Run in VS Code

1. Open this entire folder with **File → Open Folder…** (the folder containing
   `Project.toml`). Install the recommended **Julia** extension if needed.
2. Open the Command Palette (`Cmd+Shift+P` on macOS) and run
   **Tasks: Run Task → Julia: Instantiate project** once to install dependencies.
   The macOS tasks use the Juliaup executable at `~/.juliaup/bin/julia`;
   other platforms use `julia` from `PATH`.
3. Open `examples/tripolar.jl`. In **Run and Debug**, select
   **Julia: Cable example**, then choose **Run → Run Without Debugging**.
   It prints the results for a seven-conductor cable at three frequencies:
   `Z` and `Y` have size `(7, 7, 3)`, and `Yn` has size `(14, 14, 3)`.
4. To debug, set a breakpoint on `Z, Y = zy_cabo(...)` and press **F5**
   (**Run → Start Debugging**). Inspect `cable` and `s`, step over the call to
   inspect `Z` and `Y`, or step into the package source.

Use **Julia: Tests** in Run and Debug to debug the test suite. To run the
standard package tests, use **Tasks: Run Task → Julia: Run tests**.
The launch configurations select this project's environment and working directory.
The debugger settings allow stepping into `TransitoriosCabos` and its submodules,
while dependencies run in compiled mode for speed.
See the official [running code](https://www.julia-vscode.org/docs/stable/userguide/runningcode/)
and [debugger](https://www.julia-vscode.org/docs/stable/userguide/debugging/) guides.

## Interactive Julia REPL

Run **Julia: Start REPL** from the Command Palette. The status bar should show
this project's Julia environment. Then run:

```julia
using TransitoriosCabos
include("examples/tripolar.jl")
include("test/runtests.jl")
```

For an existing REPL started in another environment, first run
`using Pkg; Pkg.activate(".")` from the project root. Restart the REPL after
changing package source so the next `using TransitoriosCabos` loads the changes.

## Terminal commands

From the project root, including VS Code's integrated terminal:

```sh
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia --project=. examples/tripolar.jl
julia --project=. -e 'using Pkg; Pkg.test()'
```

For a quick test run using the current environment:

```sh
julia --project=. test/runtests.jl
```

## Troubleshooting

- **`Package TransitoriosCabos not found` / `Package NPZ not found`:** use the
  project environment (`--project=.` in the terminal), instantiate it, and restart
  any REPL that was opened before switching environments.
- **`opening file "fixtures/...": No such file or directory`:** test fixtures
  are now resolved with `joinpath(@__DIR__, "fixtures", ...)`, so the tests can
  run from the project root or another working directory.
- **Julia executable not found:** on this Mac, set VS Code's user setting
  **Julia: Executable Path** to the full path of `~/.juliaup/bin/julia`
  (expand `~` to your home directory). For a non-Juliaup macOS installation,
  also update the `osx.command` entries in `.vscode/tasks.json`.
- **Wrong environment after opening the folder:** run **Developer: Reload Window**;
  `.vscode/settings.json` selects `${workspaceFolder}` as the Julia environment.
- **Cannot step into package functions:** run
  **Julia: Apply default compiled modules/functions** from the Command Palette
  and restart the debug session. `julia.debuggerDefaultCompiled` includes
  `"-TransitoriosCabos."` to enable debugging inside the package and its submodules.
- **Running a file in `src/cabos` or `src/formulas` gives undefined names:** these
  files belong to submodules and are loaded by the package. Run the example or
  tests, and use `using TransitoriosCabos` in your own scripts.
