# Remove cached files

Deletes the yearly election files, the cached parliamentary tables and
the snapshots stored in `cache_dir`. The next query downloads them
again.

## Usage

``` r
elected_clear_cache(cache_dir = tools::R_user_dir("electedBR", "cache"))

limpar_cache_eleitos(cache_dir = tools::R_user_dir("electedBR", "cache"))
```

## Arguments

- cache_dir:

  Cache directory; the package default is
  `tools::R_user_dir("electedBR", "cache")`.

## Value

The number of files removed, invisibly.

## Examples

``` r
dir <- file.path(tempdir(), "electedBR-example")
dir.create(dir)
writeLines("x", file.path(dir, "elected_2024.parquet"))
elected_clear_cache(dir)
```
