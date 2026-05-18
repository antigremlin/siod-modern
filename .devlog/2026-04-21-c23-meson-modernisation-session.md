# C23 Meson Modernisation Session

Date: 2026-04-21

Range covered: `82533ab7a6e357ce49298323bb1b8e34eab13f65..1444f4ddfda9f28946fdab679a90d21aef0630fb`

This report covers all commits after the initial SIOD checkin through `1444f4d add initial test suite`.

## Summary

This session turned the initial SIOD source import into a buildable modern C project. The main goals were to add a Meson/Ninja/clang workflow, compile the interpreter as C23, make the macOS build work, and reduce the most important compiler warnings.

By the end of the range the repository had:

- project tooling via `mise.toml`, `meson.build`, and `meson.options`
- a C23 Meson build for a static SIOD library plus `siod` executable
- optional AddressSanitizer/UBSan support through `-Dsanitize=true`
- C23 compilation fixes for legacy K&R definitions and implicit `int`
- macOS portability fixes around POSIX feature guards, `PATH_MAX`, `dlfcn.h`, `putpwent`, and `random()`
- a completed modernization tracker in `plans/modernise.md`
- targeted fixes for format, signedness, dangling-else, parentheses, unused-parameter, and function-pointer-cast warnings
- several undefined-behavior reductions in the interpreter dispatch and reader callback paths
- a first Scheme test suite covering core language behavior and GC stress

The end-of-session `AGENTS.md` recorded a clean C23 build under `-Wall -Wextra` with three remaining warnings: `dflag`, `seed`, and `data` as `-Wunused-but-set-variable`.

## Build And Tooling

The first pass added local project instructions and tool setup:

- `AGENTS.md` documented the SIOD modernization goal, build commands, and status.
- `CLAUDE.md` pointed agents back to `AGENTS.md`.
- `mise.toml` selected the expected local tools: Meson, Ninja, and clang.
- `.gitignore` ignored build and clangd cache output.

The main build commit added:

- `meson.build` with project version `3.6`
- `c_std=c23`, `warning_level=2`, and `debugoptimized`
- a `libsiod` static library from `slib.c`, `sliba.c`, `trace.c`, `slibu.c`, and `md5.c`
- a `siod` executable linked against that library
- `-Dunix`, needed because macOS does not predefine `unix` while the legacy source uses it around POSIX includes
- `meson.options` with a `sanitize` boolean that enables `-fsanitize=address,undefined` and `-fno-sanitize-recover=all`

This changed the project from "source import" to "repeatably buildable with Meson and Ninja".

## C23 And macOS Porting

Several changes were required before the old code could build as C23 on macOS:

- `md5.c` K&R function definitions were converted to ANSI-style prototypes, because C23 no longer supports old-style definitions.
- `process_cla()` gained an explicit `int` on the static `siod_lib_set` variable, replacing legacy implicit `int`.
- `sprintf_s` was aliased to `snprintf` for all non-Windows builds, not just Linux.
- `slibu.c` now includes `<limits.h>` and `<dlfcn.h>` for macOS in the legacy platform-guard style.
- `putpwent` support was guarded behind `#ifdef linux`, because macOS does not provide it.
- `lrandom()` was extended to use `random()` on `__APPLE__`, fixing an uninitialized result on macOS.

These were intentionally small compatibility edits, keeping the old platform-conditional structure intact while getting the modern Apple clang build through C23.

## Warning Cleanup

The first warning-reduction pass fixed one real uninitialized-variable path and twelve format warnings:

- `lrandom()` no longer leaves `res` uninitialized on macOS.
- `number->string` width and precision arguments are cast to `int`, matching `%*` and `%.*`.
- `fast_save()` now formats `sizeof(long)` and `sizeof(double)` with `%zu`.

The later warning pass reduced noise in the remaining `-Wall -Wextra` output:

- removed redundant parentheses from a GC mark comparison
- braced dangling `if`/`else` nests in GC status, reader whitespace flushing, and `butlast`
- fixed `base64_decode_table` indexing by casting the table character to `unsigned char`
- resolved two sign-comparison warnings with targeted casts

These changes were mostly behavior-preserving, but they make the compiler's parse match the maintainer's intent and reduce the chance of future warning fatigue.

## Undefined Behavior And Type Modernization

The modernization plan captured six focused C-language improvements, all completed in this session.

### Noreturn error paths

`err()`, `gc_fatal_error()`, and `quit()` were marked `[[noreturn]]`.

This matches the actual behavior: these functions either `longjmp()` or exit. The change lets the compiler understand control flow and removes the need for callers to pretend that `return err(...)` can continue normally.

One real semantic issue was clarified at the same time: after a fatal error hook runs, `err()` now always calls `exit(10)`. Before this, the hook path could theoretically fall through.

### Fixed-width MD5 types

`md5.h` now includes `<stdint.h>` and maps the old `UINT2`/`UINT4` names to `uint16_t` and `uint32_t`.

The previous typedefs encoded a pre-C99 portability workaround. The new definitions state the MD5 word sizes directly and avoid platform-dependent assumptions about `unsigned long`.

### Atomic signal flags

`nointerrupt` and `interrupt_differed` moved from plain `long` globals to `_Atomic int`.

Both variables are written from signal handlers and read from normal interpreter code. Plain non-atomic access across that boundary is undefined behavior under the C memory model, so this was a correctness modernization rather than a cosmetic warning fix.

### Typed subr initialization

The largest structural cleanup removed incompatible function-pointer casts from SIOD's built-in subroutine registration path.

Before this session, `init_subr_1`, `init_subr_2`, and related helpers cast every function pointer to `SUBR_FUNC`, the zero-argument form, before storing it. Runtime dispatch later called those functions through arity-specific union fields. Calling through an incompatible function pointer type is undefined behavior and produced cast-function-type warnings.

The fix added an `INIT_SUBR` helper that allocates the cell and stores the incoming function pointer directly into the correctly typed union member (`subr1`, `subr2`, `subrm`, and so on). Runtime dispatch did not need to change because it already read from those typed fields.

### Required but unused parameters

`[[maybe_unused]]` was added to ABI-required or dispatch-required parameters in signal handlers, stubs, and callback-style functions.

Examples include `handle_sigint`, `handle_sigfpe`, `handle_sigalrm`, `ignore_puts`, `ignore_print`, `rfs_ungetc`, `err_stack`, `setprop`, parser hooks, and evaluator helpers. This kept the source names readable while making the intent explicit to the compiler.

### GC layout assertions

Three `_Static_assert` checks now guard assumptions used by the stop-and-copy GC:

- `LISP` must be the size of a plain pointer.
- a forwarding pointer must fit inside one heap cell.
- the GC header fields must fit at the start of a cell.

The GC still relies on old-school heap layout mechanics, but these checks make platform surprises fail at compile time instead of as silent heap corruption.

## Reader Callback Cast Fix

One additional undefined-behavior fix landed after the modernization tracker was marked complete.

`read_from_string()` had been assigning `rfs_getc` and `rfs_ungetc` to the generic reader callback slots by casting their function pointer types. That is undefined behavior for the same reason as the subr dispatch issue.

The fix added small adapters, `rfs_getc_cb` and `rfs_ungetc_cb`, with the exact `gen_readio` callback signatures. Each adapter casts the callback payload back to `unsigned char **` and forwards to the existing implementation. The call site now stores correctly typed callbacks without casts.

## Initial Test Suite

The final commit in the range added `test-suite.scm`, a 301-line Scheme test file intended to exercise core SIOD behavior under normal and sanitizer builds.

The suite covers:

- arithmetic and comparison
- boolean forms
- list operations
- `mapcar`, `subset`, and `apply`
- strings, symbols, and type reporting
- `let`, `let*`, and `letrec`
- closures and higher-order functions
- recursion and accumulator-style loops
- `while`, `cond`, `begin`, `set!`, and `prog1`
- SIOD arrays, hash tables, and variable-arity functions
- `catch`/`throw`
- sorting and bit operations
- destructive list operations
- deep recursion
- GC stress with 100,000 cons cells
- `read-from-string`, `print-to-string`, and base64 round-tripping

Failures call `(error ...)`, making the script suitable as a simple non-zero-exit regression check.

## Documentation Left Behind

The session also created and maintained project-facing documentation:

- `AGENTS.md` captured the toolchain, build commands, macOS fixes, warning status, and completed modernization items.
- `plans/modernise.md` recorded the six-point modernization tracker and the rationale for each item.
- `CLAUDE.md` delegated agent instructions to `AGENTS.md`.

The docs were updated during the session as the warning count changed from the larger initial list down to the final three known warnings.

## Commits Covered

- `22b3150 add agent instructions`
- `1d47b34 set up tools`
- `b9d7acf Add meson+ninja+clang build; fix C23 compilation errors`
- `ad3748b Fix uninitialized variable and 12 format warnings`
- `9914926 Add modernisation plan and update CLAUDE.md`
- `557e2a3 Update AGENTS.md with toolchain setup and modernisation status`
- `9a1ca87 ignore cache`
- `a694b87 Add [[noreturn]] to err(), gc_fatal_error(), quit()`
- `cfa87cb Replace hand-rolled UINT2/UINT4 with <stdint.h> types in md5.h`
- `d439e7c Use _Atomic int for signal-handler globals nointerrupt and interrupt_differed`
- `b18c237 Fix SUBR_FUNC cast UB: store function pointers into typed union fields`
- `0a8046f Add [[maybe_unused]] to required-but-unused parameters`
- `2c518d5 Add _Static_assert guards on GC layout invariants`
- `81b11ea Mark all modernisation plan items complete`
- `38e5602 Update AGENTS.md: document 12 remaining warnings and completed plan`
- `0866f6d Fix rfs_getc/rfs_ungetc function-pointer cast UB in sliba.c`
- `722215a Fix -Wparentheses-equality and four -Wdangling-else warnings`
- `c930109 Fix -Wchar-subscripts and two -Wsign-compare warnings`
- `b8cb2d7 Update AGENTS.md: trim warning details, update count to 3`
- `1444f4d add initial test suite`
