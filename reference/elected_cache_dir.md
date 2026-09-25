# Cache directory

Directory where the yearly election files, the parliamentary tables and
their snapshots are stored. By default it is a folder under the
session's [`tempdir()`](https://rdrr.io/r/base/tempfile.html), so
nothing persists between sessions and nothing is written outside the
temporary directory unless you opt in. To keep the files between
sessions, set the environment variable `ELECTEDBR_CACHE_DIR` or the
option `electedBR.cache_dir` (for example to
`tools::R_user_dir("electedBR", "cache")`), or pass `cache_dir` to each
function. The precedence is: the `cache_dir` argument, then the
environment variable, then the option, then
[`tempdir()`](https://rdrr.io/r/base/tempfile.html).

## Usage

``` r
elected_cache_dir(path = NULL)

diretorio_cache_eleitos(caminho = NULL)
```

## Arguments

- path:

  Optional directory; when given, it is returned (created if needed)
  instead of the default resolution.

- caminho:

  Portuguese alias of `path`.

## Value

The cache directory path, created if needed, invisibly.

## Details

The parliamentary functions also keep a snapshot of every completed
collection under `cache_dir/snapshots/`; with a persistent cache these
accumulate and can be removed with
[`elected_clear_cache()`](https://strategicprojects.github.io/electedBR/reference/elected_clear_cache.md).

## Examples

``` r
elected_cache_dir()
old <- Sys.getenv("ELECTEDBR_CACHE_DIR", unset = NA)
Sys.setenv(ELECTEDBR_CACHE_DIR = file.path(tempdir(), "electedBR-persistent"))
elected_cache_dir()
if (is.na(old)) Sys.unsetenv("ELECTEDBR_CACHE_DIR") else
  Sys.setenv(ELECTEDBR_CACHE_DIR = old)
```
