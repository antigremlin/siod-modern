# SIOD Modernisation Plan

## Tracker

- [ ] `[[noreturn]]` on `err()`, `gc_fatal_error()`, `quit()`
- [ ] `<stdint.h>` — replace `long`-as-integer and hand-rolled `UINT4` with `uint32_t`, `size_t`, etc.
- [ ] `_Atomic` on signal-handler globals (`nointerrupt`, `interrupt_differed`)
- [ ] Fix `SUBR_FUNC` cast UB — store function pointers directly into typed union fields
- [ ] `[[maybe_unused]]` on required-but-unused parameters (signal handlers, stubs)
- [ ] `_Static_assert` on GC layout invariants

---

## Details

### `[[noreturn]]` / `_Noreturn` on `err()` and friends (C23/C11)

`err()`, `gc_fatal_error()`, and `quit()` never return — they longjmp or exit.
Without `[[noreturn]]`, the compiler emits spurious "control reaches end of
non-void function" warnings and misses dead-code elimination. Every caller that
does `return err(...)` is working around this. This would clean up a lot of
noise across all three big files (`slib.c`, `sliba.c`, `slibu.c`).

### `<stdint.h>` types replacing ad-hoc `long`/`UINT4` (C99)

The code uses `long` to mean both "Scheme integer" and "array dimension" and
sometimes "boolean return". `md5.h` has a hand-rolled `UINT4` typedef for a
32-bit word. Replacing with `uint32_t`, `int32_t`, `size_t` where appropriate
makes the intent clear and removes sign-compare warnings.

### `_Atomic` on signal-handler globals (C11)

`nointerrupt` and `interrupt_differed` in `siodp.h` are plain `long`, written
from signal handlers and read from normal code. That is undefined behavior —
they need `volatile sig_atomic_t` at minimum, or `_Atomic int` for correctness
with the C11 memory model.

### Fix the `SUBR_FUNC` cast UB (C99 + design change)

The biggest structural issue. All function pointers — `LISP (*f)(void)`,
`LISP (*f)(LISP)`, `LISP (*f)(LISP,LISP)`, etc. — are stored as `SUBR_FUNC`
(the zero-argument form) and cast back at call time. This is undefined behavior
and causes the `Wcast-function-type-mismatch` warnings in `slib.c`.

The fix is minimal: the `subr0`/`subr1`/`subr2`… fields are already separate
union members in `struct obj`. The only wrong step is in `init_subr()`, which
casts to `SUBR_FUNC` before storing. Making each `init_subr_N` store directly
into the correct union field eliminates the UB without changing the runtime
dispatch.

### `[[maybe_unused]]` on stub parameters (C23)

Signal handlers (`handle_sigint(int sig)`) and a handful of stubs have
parameters they are required to accept by ABI but do not use. `[[maybe_unused]]`
is cleaner than `(void)sig` casts and documents intent explicitly.

### `_Static_assert` on GC layout invariants (C11)

The stop-and-copy GC scans memory as arrays of `struct obj`, with implicit
assumptions about `sizeof(struct obj)` and `LISP` being a plain pointer.
Adding `_Static_assert(sizeof(LISP) == sizeof(void *), "...")` and similar
guards catches platform surprises at compile time instead of silently producing
wrong GC behavior.
