# Contributing to electedBR

Thanks for your interest in improving **electedBR**! This document
explains how to propose changes and what we expect from contributions.

## Filing an issue

- **Bugs**: please include a minimal reproducible example (consider
  [reprex](https://reprex.tidyverse.org)), the output of
  [`sessionInfo()`](https://rdrr.io/r/utils/sessionInfo.html) and, for
  API errors, the URL shown in the error message.
- **Data issues** (a candidate missing or misclassified in a yearly
  file): give the year, state, municipality and `candidate_id`, and if
  possible the matching rows of the TSE *votação nominal por município e
  zona* file.
- **Feature requests**: describe the use case first; API design follows
  from it.

## Pull requests

1.  Fork the repo and create a branch from `main`.
2.  Make your changes:
    - Public API is in **English**, with a Portuguese alias for every
      exported function (`consultar_*`). Keep both in sync.
    - Election results
      ([`get_elected()`](https://strategicprojects.github.io/electedBR/reference/get_elected.md))
      and current office holding
      ([`get_deputies()`](https://strategicprojects.github.io/electedBR/reference/get_deputies.md),
      [`get_senators()`](https://strategicprojects.github.io/electedBR/reference/get_deputies.md))
      are distinct questions; do not merge them or infer one from the
      other.
    - Document with roxygen2 (markdown enabled) and run
      `devtools::document()`; do not edit `man/*.Rd` or `NAMESPACE` by
      hand.
3.  Add tests. We use testthat (3e); tests run offline against small
    fixtures (see `tests/testthat/helper-fixtures.R`).
4.  Run `devtools::test()` and `devtools::check()` locally; both must
    pass with no errors, warnings or notes.
5.  Add a bullet to `NEWS.md` under the development version.

## Updating the data

The yearly files are built by `data-raw/build_elected.R` from the TSE
zips, uploaded with `data-raw/upload_data.sh` and indexed by
`data-raw/elected_years.R`. See the comments in those scripts.

## Code of conduct

Please note that this project is released with a [Contributor Code of
Conduct](https://strategicprojects.github.io/electedBR/CODE_OF_CONDUCT.md).
By participating you agree to abide by its terms.
