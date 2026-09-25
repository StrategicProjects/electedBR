# Remove cached files

Deletes the yearly election files, the cached parliamentary tables and
the snapshots stored in `cache_dir`. The next query downloads them
again.

## Usage

``` r
elected_clear_cache(cache_dir = elected_cache_dir())

limpar_cache_eleitos(cache_dir = elected_cache_dir())
```

## Arguments

- cache_dir:

  Cache directory; see
  [`elected_cache_dir()`](https://strategicprojects.github.io/electedBR/reference/elected_cache_dir.md).

## Value

The number of files removed, invisibly.

## Examples

``` r
dir <- file.path(tempdir(), "electedBR-example")
dir.create(dir)
writeLines("x", file.path(dir, "elected_2024.parquet"))
elected_clear_cache(dir)
```
