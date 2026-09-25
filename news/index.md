# Changelog

## electedBR 0.1.0

First CRAN release.

- Election results are read from yearly Parquet files derived from the
  TSE open data and hosted on Hugging Face
  (<https://huggingface.co/datasets/mlkwy/electedBR>), indexed by the
  new `elected_years` dataset. The first query for a year downloads a
  few megabytes into the user cache; `electionsBR` is no longer a
  dependency and the multi-hundred-megabyte TSE downloads are gone.
  [`normalize_elected()`](https://strategicprojects.github.io/electedBR/reference/normalize_elected.md)
  remains exported and is the function that builds those files.
- [`get_elected()`](https://strategicprojects.github.io/electedBR/reference/get_elected.md)
  covers mayors, deputy mayors and councilors (2020, 2024) and senators
  and federal, state and district deputies (2018, 2022); `office`
  defaults to every office of the year. `base_url` / option
  `electedBR.base_url` select a mirror. New
  [`elected_clear_cache()`](https://strategicprojects.github.io/electedBR/reference/elected_clear_cache.md).
- Sitting federal deputies and senators from the official open data APIs
  ([`get_deputies()`](https://strategicprojects.github.io/electedBR/reference/get_deputies.md),
  [`get_senators()`](https://strategicprojects.github.io/electedBR/reference/get_deputies.md))
  and per-member service history
  ([`get_service_history()`](https://strategicprojects.github.io/electedBR/reference/get_service_history.md)),
  with a six-hour configurable cache and immutable local snapshots; a
  failed collection never returns expired data silently.
- Every function returns a tibble with English columns and has a
  Portuguese alias
  ([`consultar_eleitos()`](https://strategicprojects.github.io/electedBR/reference/get_elected.md),
  [`consultar_prefeitos()`](https://strategicprojects.github.io/electedBR/reference/get_elected.md),
  [`consultar_vereadores()`](https://strategicprojects.github.io/electedBR/reference/get_elected.md),
  [`consultar_deputados()`](https://strategicprojects.github.io/electedBR/reference/get_deputies.md),
  [`consultar_senadores()`](https://strategicprojects.github.io/electedBR/reference/get_deputies.md),
  [`consultar_historico_exercicio()`](https://strategicprojects.github.io/electedBR/reference/get_service_history.md),
  [`normalizar_eleitos()`](https://strategicprojects.github.io/electedBR/reference/normalize_elected.md),
  [`limpar_cache_eleitos()`](https://strategicprojects.github.io/electedBR/reference/elected_clear_cache.md)).
  The bare aliases `eleitos()`, `prefeitos()` and `vereadores()` of the
  prototype were removed.
- Error messages are in English; roxygen2 documentation, pkgdown site
  and an offline test suite.
