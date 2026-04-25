# pyffi-natipkg-bundle

Relocatable CPython 3.12 bundles for the four
[`soegaard/pyffi`](https://github.com/soegaard/pyffi) natipkg
companion packages.

Each subdirectory is an independent Racket package on the catalog;
`pyffi-lib`'s `platform-deps` selects whichever one matches the
user's host (`(system-type)`).

| Subdirectory | Catalog package | Target |
|---|---|---|
| [`pyffi-aarch64-linux-natipkg/`](pyffi-aarch64-linux-natipkg/) | `pyffi-aarch64-linux-natipkg` | aarch64 Linux (glibc) |
| [`pyffi-x86_64-linux-natipkg/`](pyffi-x86_64-linux-natipkg/) | `pyffi-x86_64-linux-natipkg` | x86_64 Linux (glibc) — including the package-build server |
| [`pyffi-aarch64-macosx-natipkg/`](pyffi-aarch64-macosx-natipkg/) | `pyffi-aarch64-macosx-natipkg` | aarch64 macOS (Apple Silicon) |
| [`pyffi-x86_64-macosx-natipkg/`](pyffi-x86_64-macosx-natipkg/) | `pyffi-x86_64-macosx-natipkg` | x86_64 macOS (Intel) |

Each catalog entry sources from this monorepo with a
`?path=<subdir>#main` query string, so updating the bundled Python
across all four targets is one commit here.

## Contents

Every subdirectory has the same shape:

    <subdir>/
      info.rkt                              # Racket package metadata
      lib/
        libpython3.12.{so.1.0,dylib}        # the shared library
        libpython3.{12,}.so (linux only)    # loader symlinks
        python3.12/                         # the standard library

The Linux variants ship the python-build-standalone
`install_only_stripped` build to keep individual files under
GitHub's 100 MB hard limit. macOS ships the dynamically-linked
`install_only` build (already small, no stripped variant
published).

## Source

[astral-sh/python-build-standalone](https://github.com/astral-sh/python-build-standalone)
release **20260414**, Python **3.12.13**.

## Licence

CPython is distributed under the
[PSF licence](https://docs.python.org/3/license.html).
