# Clang-Tidy Session Report

Date: 2026-05-12

Range covered: `0bf036f011d90562d0abe4267f00ead0f5ad8d86^..HEAD`

Excluded from this report: `58f614f set tabsize for old C code`, which only touched `.zed/settings.json`.

## Summary

This session introduced clang-tidy support for the SIOD modernization work, connected it to Meson's built-in clang-tidy target, and fixed the most useful warnings found so far. The repo now uses Meson's auto-generated `clang-tidy` and `clang-tidy-fix` targets rather than a project-local custom target.

The current clang-tidy run completes successfully under `mise exec -- ninja -C build clang-tidy`. It still reports analyzer warnings in MD5 and GC-related code, plus one GC hook dead-store warning that was intentionally left for a separate semantic pass.

## Clang-Tidy Setup

### Configuration

Added `.clang-tidy` with:

```yaml
---
Checks: >
  clang-diagnostic-*,
  clang-analyzer-*,
  -clang-analyzer-security.insecureAPI.DeprecatedOrUnsafeBufferHandling,
  -clang-analyzer-security.insecureAPI.rand
WarningsAsErrors: ''
HeaderFilterRegex: ''
FormatStyle: none
```

The config enables compiler diagnostics and Clang Static Analyzer checks, but keeps two noisy legacy C insecure API checks disabled for now. `FormatStyle: none` keeps clang-tidy from driving formatting changes while clang-format policy is still being decided.

### Meson Integration

Meson automatically creates `clang-tidy` and `clang-tidy-fix` targets when:

- `clang-tidy` is on `PATH` at setup time,
- the source root contains `.clang-tidy`, and
- the project does not define its own `clang-tidy` target.

The project now declares:

```meson
project('siod', 'c',
  version : '3.6',
  meson_version : '>=1.9.0',
  default_options : [
    'c_std=c23',
    'warning_level=2',
    'buildtype=debugoptimized',
  ],
)
```

The `>=1.9.0` floor both removes Meson's minimum-version warning and matches the version where Meson's auto-generated clang-tidy target correctly selects only source files participating in build targets.

No custom Meson `run_target()` is needed.

### Mise and Homebrew LLVM

Homebrew LLVM is keg-only and lives at:

```sh
/opt/homebrew/opt/llvm/bin
```

The project-level `mise.toml` now adds that directory to the mise execution environment:

```toml
[env]
_.path = "/opt/homebrew/opt/llvm/bin"
_.source = "vars.sh"
```

The earlier shell-alias approach was not enough for Meson. Shell aliases work interactively, but Meson and Ninja need a real executable on `PATH`.

Because the full project mise environment is loaded through shell rc files, the reliable way to run commands from this automation context is:

```sh
mise exec -- meson setup build
mise exec -- ninja -C build clang-tidy
```

### macOS SDK Details

Homebrew `clang-tidy` needs Apple's SDK path to find system headers such as `stdio.h`. The project now sources `vars.sh`:

```sh
if [ "$(uname -s)" = "Darwin" ] && command -v xcrun >/dev/null 2>&1; then
  export SDKROOT="${SDKROOT:-$(xcrun --show-sdk-path)}"
fi
```

This is deliberately macOS-only and preserves an existing `SDKROOT` if one is already set.

The normal build still uses Apple clang through `/usr/bin/cc`; Homebrew LLVM is used for `clang-tidy` and `clang-format`.

### Homebrew LLVM Coexistence Recommendation

Homebrew warns that placing its LLVM package ahead of Apple's toolchain can cause trouble. For this repo, the current setup is acceptable because Meson is compiling with `cc`, which resolves to `/usr/bin/cc`, while Homebrew `clang-tidy` only analyzes the compile database.

The preferred longer-term setup is recommendation 2 from the discussion: create a small project-local shim directory that exposes only `clang-tidy` and `clang-format`, then add that shim directory to `PATH`. That avoids shadowing Apple's `clang` while still letting Meson discover clang-tidy automatically.

## Warning Fixes

### Null Inferred String Length

Commit: `11bbd19 Guard strcons against null inferred length`

`strcons()` previously called `strlen(data)` whenever `length < 0`. Clang-tidy found a path where `data` could be null. The function now reports an error before attempting to infer length from a null pointer.

### Unused Dead Stores

Commit: `3005f6c Remove unused dead stores`

Fixed several low-risk dead stores:

- `f_getc()` now keeps `dflag` only for the VMS-only path that uses it.
- `lsrandom()` now uses the `seed` value on macOS via `srandom(seed)`.
- `datlength()` still calls `get_c_string_dim(dat, &size)` for validation and side effects, but no longer stores the unused returned data pointer.

### Varargs Analyzer False Positives

Commit: `ba886d0 Document varargs analyzer false positives`

Added targeted `NOLINTNEXTLINE(clang-analyzer-security.VAList)` comments at the varargs sites where clang-tidy loses track of a valid `va_start()` through SIOD macros:

- `listn`
- `assemble_options`
- `symalist`

A helper-function refactor was explored, but clang-tidy still reported the warning. Targeted suppressions were chosen because the existing varargs APIs are public and widely used.

### Local Analyzer Dead Stores

Commit: `3b30052 Clean up local analyzer dead stores`

Cleaned up additional analyzer reports:

- `allocate_aheap()` now restores interrupt state with `no_interrupt(flag)` without assigning the unused return value.
- `gc_sweep()` moved `end` into the inner heap scope.
- `lexit()` keeps interrupts disabled before `exit()` and removes the unreachable restore assignment.
- `lgets()` removes a leftover `ptr` variable and checks `fgets()` directly.

### Command-Line Option Leak

Commit: `a8c57a8 Free temporary -m argument in siod_main`

The analyzer reported a leak in `siod_main()` around comma-split command-line option handling. This was real for the `-m...` path: the temporary split argument was allocated, used locally to set `mainflag`, and never passed to `process_cla()`.

The fix frees the temporary string only on the `-m` path:

```c
if ((strncmp(iargv[1],"-m",2) == 0))
  {mainflag = atol(&iargv[1][2]);
   free(iargv[1]);}
else
  process_cla(2,iargv,1);
```

The other path still intentionally does not free `iargv[1]`, because `process_cla()` can store pointers into that string for options such as `-l...` and `-i...`.

## Other Changes

Commit: `0bf036f Add clang-tidy config and LLVM aliases`

Introduced the first clang-tidy configuration and Homebrew LLVM command discovery setup.

Commit: `0250741 Add Meson version floor and macOS clang-tidy SDKROOT setup`

Added `meson_version : '>=1.9.0'`, moved from aliases toward a real mise environment path, and added macOS SDK discovery through `vars.sh`.

## Verification

The following commands pass:

```sh
mise exec -- ninja -C build
mise exec -- ninja -C build clang-tidy
```

The current clang-tidy invocation exits `0`.

Remaining warnings at the end of the session:

- `md5.c:140` and `md5.c:149`: analyzer reports possible out-of-bounds access around MD5 padding.
- `slib.c:623`: possible null-pointer subtraction involving `cw` in REPL/GC status reporting.
- `slib.c:1031`, `slib.c:1044`, `slib.c:1072`, and `slib.c:1290`: analyzer reports around heap/GC storage.
- `slib.c:1401`: dead store from `ptr = (*p->gc_mark)(ptr)`, left for a separate GC hook semantics pass.

## Commits Covered

- `0bf036f Add clang-tidy config and LLVM aliases`
- `11bbd19 Guard strcons against null inferred length`
- `3005f6c Remove unused dead stores`
- `ba886d0 Document varargs analyzer false positives`
- `3b30052 Clean up local analyzer dead stores`
- `0250741 Add Meson version floor and macOS clang-tidy SDKROOT setup`
- `a8c57a8 Free temporary -m argument in siod_main`

Excluded:

- `58f614f set tabsize for old C code`
