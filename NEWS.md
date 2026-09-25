# electedBR 0.1.0

First CRAN release.

* Election results are read from yearly Parquet files derived from the TSE
  open data and hosted on Hugging Face
  (<https://huggingface.co/datasets/mlkwy/electedBR>), indexed by the new
  `elected_years` dataset. The first query for a year downloads 1 to 25 MB
  into the cache directory (`elected_cache_dir()`: a folder under
  `tempdir()` by default, persistent when `ELECTEDBR_CACHE_DIR` or the
  `electedBR.cache_dir` option is set); `electionsBR` is no longer a dependency and
  the multi-hundred-megabyte TSE downloads are gone. `normalize_elected()`
  remains exported and is the function that builds those files.
* `get_elected()` covers mayors, vice mayors and councilors (2020, 2024) and
  president, vice president, governors, vice governors, senators and federal,
  state and district deputies (2018, 2022); `office` defaults to every office
  of the year. Running mates come from the TSE candidates file, with
  `votes = NA` and `ticket_candidate_id` linking them to the head of the
  ticket. `base_url` / option `electedBR.base_url` select a mirror. New
  `elected_clear_cache()`.
* New `get_officeholding_events()`: a curated table of resignations, deaths,
  removals, leaves and successions for mayors and governors, served next to
  the yearly files. `get_elected(as_of = )` applies it and adds
  `status_as_of`, `status_date`, `office_as_of` and `status_source`.
* Sitting federal deputies and senators from the official open data APIs
  (`get_deputies()`, `get_senators()`) and per-member service history
  (`get_service_history()`), with a six-hour configurable cache and immutable
  local snapshots; a failed collection never returns expired data silently.
* Every function returns a tibble with English columns and has a Portuguese
  alias (`consultar_eleitos()`, `consultar_prefeitos()`,
  `consultar_vereadores()`, `consultar_deputados()`, `consultar_senadores()`,
  `consultar_historico_exercicio()`, `consultar_eventos_exercicio()`,
  `normalizar_eleitos()`, `limpar_cache_eleitos()`). The bare aliases `eleitos()`, `prefeitos()` and
  `vereadores()` of the prototype were removed.
* Error messages are in English; roxygen2 documentation, pkgdown site and an
  offline test suite.
