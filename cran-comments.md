## Submission: electedBR 0.1.0

This is a new submission.

## R CMD check results

0 errors | 0 warnings | 0 notes

## Test environments

* local: macOS (aarch64-apple-darwin), R 4.6.0
* GitHub Actions: macOS (release), Windows (release), Ubuntu (devel, release,
  oldrel-1)

## Notes for the reviewers

* Examples that download data or query the Chamber of Deputies and Federal
  Senate open data APIs are wrapped in \donttest{} and write only to
  `tempdir()`. Tests run offline against small fixtures.
* Data files are hosted outside the package
  (<https://huggingface.co/datasets/mlkwy/electedBR>), so the package stays
  small; downloads are verified against the size and MD5 shipped in the
  `elected_years` dataset and cached in `tools::R_user_dir("electedBR", "cache")`.
