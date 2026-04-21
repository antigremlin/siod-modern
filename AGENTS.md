This is SIOD (scheme-in-one-defun), an old Scheme interpreter.
It should roughly implement R3RS Scheme.
Our goal is to modernise the source code and port it to C23.

## Toolchain

Tools are on the PATH via mise (`mise.toml`):
- **meson** — build system (`meson.build` at repo root, `meson.options` for flags)
- **ninja** — build backend
- **clang** — compiler via Xcode (`cc` on PATH)

Build and run:
```
meson setup build        # first time
ninja -C build           # compile
build/siod               # run interpreter
```

Optional sanitizers: `meson setup build -Dsanitize=true`

## Build status

The build compiles cleanly under `-std=c23 -Wall -Wextra` with **12 warnings**
remaining (down from ~36). No errors.

Remaining warnings by file:

**slib.c** (6):
- `[-Wparentheses-equality]` — extraneous parentheses in `if (((*ptr).gc_mark == 0))` (line 1455)
- `[-Wdangling-else]` — three `if … else` chains lacking braces (lines 1498, 1520, 2131); all inside macros or compact one-liners
- `[-Wunused-but-set-variable]` — `dflag` assigned but only used under a `WIN32` guard (line 2111)
- `[-Wsign-compare]` — `long` vs `unsigned long` in `sizeof` comparison (line 2341)

**sliba.c** (3):
- `[-Wcast-function-type-mismatch]` — `rfs_ungetc` cast to generic `void (*)(int,void *)` for the `gen_readio` callback (line 194); requires a small adapter function to fix cleanly
- `[-Wchar-subscripts]` — `char` used as array index into `base64_decode_table` (line 1255); needs a `(unsigned char)` cast
- `[-Wdangling-else]` — missing braces in a compact `if/else` (line 1468)

**slibu.c** (3):
- `[-Wunused-but-set-variable]` — `seed` assigned but unused (line 401); `data` assigned but unused (line 1942)
- `[-Wsign-compare]` — `long` vs `unsigned long` in `sizeof` comparison (line 1447)

macOS-specific fixes already applied:
- `sprintf_s` aliased to `snprintf` for non-WIN32 targets
- `PATH_MAX` sourced from `<limits.h>` for macOS
- `putpwent` guarded behind `#ifdef linux` (not available on macOS)
- `md5.c` K&R function definitions converted to ANSI style
- `lrandom()` covers macOS via `__APPLE__` guard on `random()`

## Modernisation plan

See `plans/modernise.md` for the full tracker and details.

All planned items are complete (committed separately):
1. `[[noreturn]]` on `err()`, `gc_fatal_error()`, `quit()`
2. `<stdint.h>` types — `UINT4`/`UINT2` replaced with `uint32_t`/`uint16_t` in `md5.h`
3. `_Atomic int` on signal-handler globals (`nointerrupt`, `interrupt_differed`)
4. Fix `SUBR_FUNC` cast UB — typed `INIT_SUBR` macro stores directly into correct union field
5. `[[maybe_unused]]` on 14 required-but-unused parameters across all three main files
6. `_Static_assert` on 3 GC layout invariants (`sizeof(LISP)`, cell size, header size)
