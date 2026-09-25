## Resubmission

This is a resubmission. In this version I have:

* Replaced the relative link to `CODE_OF_CONDUCT.md` in `README.md` with the
  absolute URL of the file on GitHub, as requested (the file is not part of
  the tarball, so the relative URI was invalid).

## Initial submission

This is the first submission of electedBR to CRAN.

## Test environments

* local macOS (R 4.6.0)
* GitHub Actions: macOS (release), Windows (release), Ubuntu (devel, release,
  oldrel-1)
* win-builder (devel)

## R CMD check results

0 errors | 0 warnings | 0 notes locally and on GitHub Actions.

win-builder (R-devel) reports 1 NOTE: "New submission", plus the possibly
misspelled words TSE (the Superior Electoral Court's acronym) and tibble
(the data structure returned by every function).

## Notes for the reviewers

* Examples that download data or query the Chamber of Deputies and Federal
  Senate open data APIs are marked `@examplesIf interactive()`, as in our
  package ibger already on CRAN, because they depend on external services
  and on a network connection. All other examples run offline in well under
  a second. Tests run offline against small fixtures
  (`testthat::local_mocked_bindings()` replaces the download).
* The package never writes outside `tempdir()` unless the user opts in: the
  cache directory defaults to a folder under `tempdir()` and becomes
  persistent only through an argument, the `ELECTEDBR_CACHE_DIR` environment
  variable or the `electedBR.cache_dir` option (documented in
  `?elected_cache_dir`).
* Data files are hosted outside the package
  (<https://huggingface.co/datasets/mlkwy/electedBR>) so that the package
  stays small; downloads are verified against the size and MD5 shipped in
  the `elected_years` dataset.
* The TSE open data portal (<https://dadosabertos.tse.jus.br/>) answers HTTP
  403 to automated clients (curl, libcurl), so URL checks report it as
  forbidden. The site is live in any browser and is the official source of
  the data, so the link is kept.
