# pyffi-natipkg-bundle

Relocatable CPython 3.12 bundles for the four
[`soegaard/pyffi`](https://github.com/soegaard/pyffi) natipkg
companion packages.

This repository exists for one reason: **to give the Racket
package-build server a real `libpython` so it can build pyffi-doc's
live Scribble examples**. End users do not normally download any
of these subdirs — they configure their own Python installation
with `raco pyffi configure` (or set `PYFFI_LIBPYTHON`/`pyffi:libdir`
directly), and pyffi calls into that.

## Why this exists

The package-build server at `pkg-build.racket-lang.org` runs on a
Linux VM that does not have any Python development files installed.
Building pyffi-doc requires evaluating Scribble examples that import
real Python modules through pyffi's FFI. Without a discoverable
`libpython.so`, the doc-build aborts and the catalog never produces
a successful pyffi build artefact. This has been the state for
1254 days as of 2026-04-25.

The fix uses the standard Racket convention for "package needs a
native library that pkg-build doesn't have":

1. Each platform-specific binary is shipped as its own native package
   (`*-natipkg`).
2. The consuming package (`pyffi-lib`) declares them as
   platform-conditional **build-deps** in `info.rkt`.
3. When pkg-build identifies its host as `x86_64-linux-natipkg`, raco
   resolves the matching natipkg, installs it alongside pyffi-lib,
   and the doc-build succeeds.

The same convention powers `math-x86_64-linux-natipkg` (LAPACK/BLAS),
`draw-x86_64-linux-natipkg-3` (Cairo/Pango), `gui-x86_64-linux-natipkg`
(Gtk), and so on.

## Layout

Each subdirectory is an independent Racket catalog package:

| Subdirectory                                                                                                        | Catalog package                  | Target                          |
| :------------------------------------------------------------------------------------------------------------------ | :------------------------------- | :------------------------------ |
| [`pyffi-aarch64-linux-natipkg/`](pyffi-aarch64-linux-natipkg/)   | `pyffi-aarch64-linux-natipkg`    | aarch64 Linux (glibc)           |
| [`pyffi-x86_64-linux-natipkg/`](pyffi-x86_64-linux-natipkg/)     | `pyffi-x86_64-linux-natipkg`     | x86_64 Linux (glibc) — pkg-build |
| [`pyffi-aarch64-macosx-natipkg/`](pyffi-aarch64-macosx-natipkg/) | `pyffi-aarch64-macosx-natipkg`   | aarch64 macOS (Apple Silicon)   |
| [`pyffi-x86_64-macosx-natipkg/`](pyffi-x86_64-macosx-natipkg/)   | `pyffi-x86_64-macosx-natipkg`    | x86_64 macOS (Intel)            |

Each has the same shape:

```
<subdir>/
  info.rkt                              Racket package metadata
  lib/
    libpython3.12.{so.1.0,dylib}        the shared library
    libpython3.12.so, libpython3.so     loader symlinks (Linux only)
    python3.12/                         the Python standard library
```

## How the catalog uses these

Each `pyffi-*-natipkg` package gets a separate catalog entry. The
source URLs are this repo with a `?path=` query string:

```
https://github.com/lamestllama/pyffi-natipkg-bundle.git?path=pyffi-aarch64-linux-natipkg#main
https://github.com/lamestllama/pyffi-natipkg-bundle.git?path=pyffi-x86_64-linux-natipkg#main
https://github.com/lamestllama/pyffi-natipkg-bundle.git?path=pyffi-aarch64-macosx-natipkg#main
https://github.com/lamestllama/pyffi-natipkg-bundle.git?path=pyffi-x86_64-macosx-natipkg#main
```

The `pkgs.racket-lang.org` catalog admin (currently soegaard for
pyffi-related packages) registers each entry once. After that,
`raco pkg install pyffi` on a host that matches one of the
platform regexes in `pyffi-lib/info.rkt`'s `build-deps` will
automatically pull in the matching natipkg during build.

## How discovery works at runtime

`pyffi-lib/pyffi/libpython.rkt` resolves `libpython` in this order:

1. `PYFFI_LIBPYTHON` environment variable (explicit override)
2. `pyffi:libdir` / `pyffi:home` preferences (set by `raco pyffi configure`)
3. **Bundled natipkg companion** (if installed — the build server's path)
4. Dynamic loader search by candidate name
5. Error

Steps 3 and 4 are fallbacks; step 1 or 2 is the path end users
take when they have their own Python installation. The natipkg
path is for environments without a system Python — the package
build server, or a user who has explicitly opted into the bundle.

## End-user install paths

| User's situation                                  | Where pyffi finds libpython                                 |
| :------------------------------------------------ | :---------------------------------------------------------- |
| Has system Python, ran `raco pyffi configure`     | The configured Python (preferences)                         |
| Has system Python, sets `PYFFI_LIBPYTHON`         | Whatever the env var points at                              |
| Wants the bundled Python explicitly               | `raco pkg install pyffi-<arch>-<os>-natipkg` then nothing else |
| Pulling prebuilt artefacts from snapshot catalog  | Already-compiled bytecode + rendered docs, no setup needed; runtime libpython still comes from preferences/env |

## Updating the bundles

Sourced from
[`astral-sh/python-build-standalone`](https://github.com/astral-sh/python-build-standalone).
Current bundles: release **20260414**, Python **3.12.13**.

To bump:

1. Pick a new release date and Python patch version from the
   python-build-standalone release page.
2. Download the four matching tarballs:
   - `cpython-<X.Y.Z>+<DATE>-aarch64-unknown-linux-gnu-install_only_stripped.tar.gz`
   - `cpython-<X.Y.Z>+<DATE>-x86_64-unknown-linux-gnu-install_only_stripped.tar.gz`
   - `cpython-<X.Y.Z>+<DATE>-aarch64-apple-darwin-install_only.tar.gz`
   - `cpython-<X.Y.Z>+<DATE>-x86_64-apple-darwin-install_only.tar.gz`
   (Linux uses the *stripped* variant to keep individual files under
   GitHub's 100 MB hard limit; macOS doesn't publish a stripped
   variant but its dylibs are dynamically linked against system
   `libssl`/`libffi`/etc. so they're already small.)
3. For each tarball, replace the matching `<subdir>/lib/`
   contents — keep the symlinks for Linux variants
   (`libpython3.12.so` → `libpython3.12.so.1.0`, `libpython3.so`).
   Update `pkg-desc` in `<subdir>/info.rkt` if the Python version
   line changed.
4. Commit the four updated subdirs together.
5. The catalog will pick up the new checksum on its next refresh;
   pkg-build will rebuild pyffi-doc with the new bundled Python.

## What's not here

- **Python 3.10 / 3.11 / 3.13 variants.** Only 3.12 is bundled.
  pyffi-lib's discovery is platform-aware but not currently
  version-aware; if a user wants 3.10 they must use a system
  install. Adding versioned natipkgs (e.g.
  `pyffi-py310-aarch64-linux-natipkg`) is straightforward future
  work.
- **Windows variants.** `python-build-standalone` publishes
  `*-pc-windows-msvc` builds, but pyffi-lib itself does not have
  a tested Windows path yet.
- **Source builds.** These bundles are pre-built binaries; we don't
  ship the matching headers or bin/python3 because pyffi only needs
  the runtime library and stdlib.

## Licence

CPython is distributed under the
[PSF licence](https://docs.python.org/3/license.html).

This repository's metadata, layout, and README are licensed
identically to the upstream `soegaard/pyffi` project.
