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
ninja -C build clean     # clean to rebuild
ninja -C build           # compile
build/siod               # run interpreter
```

Optional sanitizers: `meson setup build -Dsanitize=true`

## Build status

The build compiles cleanly under `-std=c23 -Wall -Wextra` with 3 warnings
remaining (`-Wunused-but-set-variable` for `dflag`, `seed`, `data`). No errors.

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
