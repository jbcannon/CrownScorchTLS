# CrownScorchTLS 0.1.2

- Resubmission to CRAN to restore the package after it was archived on
  2026-05-01 due to the archival of a dependency, `lidR`; `lidR` has
  since been restored to CRAN.
- Removed `LazyData: true` from DESCRIPTION (package ships no `data/`
  directory).
- Fixed a malformed `@examples` tag that had been folded into `@note`
  for `stemPoints()`.

# CrownScorchTLS 0.1.1

## Bug fixes

- Exported `stemPoints()` so it is available to users via the package namespace.
