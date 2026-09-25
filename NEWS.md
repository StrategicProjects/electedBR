# electedBR 0.1.0

First CRAN release.

* Election results are read from yearly Parquet files derived from the TSE
  open data and hosted on Hugging Face
  (<https://huggingface.co/datasets/mlkwy/electedBR>), indexed by the new
  `elected_years` dataset. The first query for a year downloads 1 to 25 MB
  into the user cache; `electionsBR` is no longer a dependency and
  the multi-hundred-megabyte TSE downloads are gone. `normalize_elected()`
  remains exported and is the function that builds those files.
* `get_elected()` covers mayors, deputy mayors and councilors (2020, 2024) and
  senators and federal, state and district deputies (2018, 2022); `office`
  defaults to every office of the year. `base_url` / option
  `electedBR.base_url` select a mirror. New `elected_clear_cache()`.
* Sitting federal deputies and senators from the official open data APIs
  (`get_deputies()`, `get_senators()`) and per-member service history
  (`get_service_history()`), with a six-hour configurable cache and immutable
  local snapshots; a failed collection never returns expired data silently.
* Every function returns a tibble with English columns and has a Portuguese
  alias (`consultar_eleitos()`, `consultar_prefeitos()`,
  `consultar_vereadores()`, `consultar_deputados()`, `consultar_senadores()`,
  `consultar_historico_exercicio()`, `normalizar_eleitos()`,
  `limpar_cache_eleitos()`). The bare aliases `eleitos()`, `prefeitos()` and
  `vereadores()` of the prototype were removed.
* Error messages are in English; roxygen2 documentation, pkgdown site and an
  offline test suite.
