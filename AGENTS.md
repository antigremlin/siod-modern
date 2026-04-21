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

The build compiles cleanly under `-std=c23 -Wall -Wextra` with ~36 warnings
remaining (all non-critical: SUBR_FUNC casts, unused params, dangling-else).
No errors.

macOS-specific fixes already applied:
- `sprintf_s` aliased to `snprintf` for non-WIN32 targets
- `PATH_MAX` sourced from `<limits.h>` for macOS
- `putpwent` guarded behind `#ifdef linux` (not available on macOS)
- `md5.c` K&R function definitions converted to ANSI style
- `lrandom()` covers macOS via `__APPLE__` guard on `random()`

## Modernisation plan

See `plans/modernise.md` for the full tracker and details.

Priority items:
1. `[[noreturn]]` on `err()`, `gc_fatal_error()`, `quit()`
2. `<stdint.h>` types replacing ad-hoc `long` and `UINT4`
3. `_Atomic` on signal-handler globals (`nointerrupt`, `interrupt_differed`)
4. Fix `SUBR_FUNC` cast UB (store into typed union fields directly)
5. `[[maybe_unused]]` on required-but-unused parameters
6. `_Static_assert` on GC layout invariants
