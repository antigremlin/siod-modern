# Supported Platforms

This document describes the modern SIOD support matrix. The historical source
tree still contains code and build files for older systems, but active support
is intentionally narrower.

## Tier 1 Targets

The core interpreter is intended to support these operating systems and CPU
architectures:

| Operating system | Architectures | Compilers |
| --- | --- | --- |
| Linux | x86_64, arm64 | GCC, Clang |
| macOS | x86_64, arm64 | Apple Clang, LLVM Clang |
| Windows | x86_64, arm64 | MSYS2 GCC, MSYS2 Clang, MSVC/clang-cl |

Tier 1 means the core interpreter should build and run the Scheme test suite.
Optional extension modules are not Tier 1 until they are added to the Meson
build with platform feature checks.

## Automated Checks

GitHub Actions currently runs:

- Linux x86_64 with GCC
- Linux x86_64 with Clang
- Windows x86_64 with MSYS2 UCRT64 GCC
- Windows x86_64 with MSYS2 CLANG64 Clang

Each job configures with Meson, builds with Ninja, and runs `test-suite.scm`
through Meson's `core-suite` test.

## Manual Checks

These targets are Tier 1 but currently require manual validation:

- macOS x86_64 and arm64 local builds
- Windows native MSVC/clang-cl builds
- Linux arm64 builds, either on native hardware or in Docker/emulation

Useful local commands:

```sh
meson setup build --reconfigure
ninja -C build
meson test -C build
build/siod test-suite.scm
```

## Unsupported Historical Targets

These systems are not active support targets:

- ia64 / Itanium
- VMS
- OSF/1
- HP-UX
- SunOS-era and legacy Solaris branches
- SGI IRIX
- OS/2
- Classic Mac / THINK C
- Amiga

Historical files for these systems may remain in the tree for reference, but
new portability work should target the Tier 1 matrix above.
