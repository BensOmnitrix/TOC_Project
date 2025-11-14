# TOC Project — Simple Turing Machine Simulator

This repository contains a small, easy-to-understand Turing Machine simulator written in a single C++ file (`tm.cpp`) and some example `.tm` machine files (for example `string_duplicate.tm`).

**Overview**
- **What:** A tiny Turing Machine simulator that loads a machine either from a built-in example or from a `.tm` file and runs it interactively or to completion.
- **Where:** Main source: `tm.cpp`. Example machines: `binary_incrementer.tm`, `palindrome_ab_hash.tm`, `anbn.tm`, `unary_add_full.tm`, `non_halting_right.tm`, `string_duplicate.tm`, etc.

**Prerequisites**
- **Compiler:** A C++17 compiler. On Windows you can use `g++` (from MinGW or MSYS2) or Microsoft Visual C++ (`cl`).

**Build (Windows cmd.exe)**
- Using `g++` (MinGW/MSYS2):

```
g++ -std=c++17 -O2 tm.cpp -o tm.exe
```

- Using MSVC `cl` (Developer Command Prompt):

```
cl /std:c++17 /O2 tm.cpp /Fe:tm.exe
```

**Run**
- Run a built-in example (non-interactive):

```
.\tm.exe --example binary_incrementer --input 101 --run
```

- Run a `.tm` file from disk (non-interactive):

```
.\tm.exe --file string_duplicate.tm --input ab --run
```

- Interactive step mode (default if you don't pass `--run`):

```
.\tm.exe --example anbn --input aabb --step
```

In interactive mode the prompt accepts:
- Press Enter to perform one step.
- `r` to run up to the step cap (`--max-steps`).
- `q` to quit.

**Git Bash / MSYS2 notes**
- The `g++` build command and the runtime examples work in Git Bash (or MSYS2) as long as you have a MinGW/MSYS2 toolchain installed and `g++` is on your `PATH`.
- In Git Bash use `./tm.exe` (forward slash) instead of `\\.\\tm.exe`:

```
./tm.exe --example binary_incrementer --input 101 --run
```

- If you compiled with MinGW/MSYS2 `g++` the produced `tm.exe` runs both in Git Bash and in `cmd.exe`.
- The Visual C++ compiler (`cl`) normally requires the Developer Command Prompt to set environment variables; it's simplest to use MinGW in Git Bash. If you prefer MSVC, run `cl` from the Visual Studio Developer Command Prompt or bootstrap the environment first.

**Command-line flags**
- `--example NAME` : use a built-in machine (examples below).
- `--file PATH`    : load machine from a `.tm` file.
- `--input STR`    : initial tape contents (first cell is head position).
- `--run`          : run until halt or step cap, then print result.
- `--step`         : interactive single-step mode (default if neither `--run` nor `--step`).
- `--max-steps N`  : maximum steps for `--run` (default 2000).
- `--window K`     : half-width of tape portion printed around the head (default 15).

**Built-in examples**
- `binary_incrementer`
- `palindrome_ab_hash`
- `anbn`
- `unary_add`
- `non_halting_right`

**.tm file format (very brief)**
- Header lines (order doesn't matter) include:
  - `states: q0,q1,...`
  - `start: STATE`
  - `accept: STATE`
  - `reject: STATE`
  - `blank: _` (single char)
  - `input_alphabet: a,b,1,0` (comma-separated)
  - `tape_alphabet: ...` (comma-separated)
  - `delta:` (starts transitions section)
- Transitions appear one per line after `delta:` using tokenized form:

```
q0 a -> x R q1
```

which reads: in state `q0` reading `a` write `x`, move `R` (or `L` or `S`), and go to `q1`.
- Lines starting with `#` or empty lines are ignored.

**Notes**
- The simulator uses a sparse tape (only non-blank cells stored).
- The default blank character is underscore (`_`).
- If a transition is missing for the current (state, symbol) the machine implicitly rejects.

