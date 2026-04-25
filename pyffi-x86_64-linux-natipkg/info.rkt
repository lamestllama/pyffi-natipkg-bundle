#lang info

(define collection 'multi)
(define deps '("base"))
(define pkg-desc
  "Relocatable CPython 3.12 (libpython + standard library) for x86_64 Linux (glibc) — used by pyffi-lib as its bundled Python when no system install is configured.")
(define pkg-authors '("jensaxel@soegaard.net"))
(define license 'PSF-2.0)

;; The package is pure binary data — a relocatable CPython tree laid
;; out under lib/.  pyffi-lib's libpython.rkt discovers this package
;; via `pkg-directory` at runtime and loads the libpython binary
;; from here; PYTHONHOME resolves to the package root so Py_Initialize
;; finds lib/python3.12 (the standard library).
;;
;; Sourced from astral-sh/python-build-standalone release 20260414,
;; Python 3.12.13.
(define build-deps '())
