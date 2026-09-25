# Candidates elected in Brazilian elections

Returns the candidates elected (and optionally the alternates) in a
Brazilian election year, from the yearly files derived from the TSE open
data and hosted by the package (see
[elected_years](https://strategicprojects.github.io/electedBR/reference/elected_years.md)).
Municipal offices (mayor, deputy mayor, councilor) are available for
municipal election years (2020, 2024, ...) and legislative offices
(senator, federal, state and district deputy) for general election years
(2018, 2022, ...).

## Usage

``` r
get_elected(
  year = 2024L,
  state = NULL,
  municipality = NULL,
  office = NULL,
  party = NULL,
  include_alternates = FALSE,
  cache_dir = tools::R_user_dir("electedBR", "cache"),
  refresh = FALSE,
  base_url = getOption("electedBR.base_url")
)

get_mayors(
  year = 2024L,
  state = NULL,
  municipality = NULL,
  party = NULL,
  cache_dir = tools::R_user_dir("electedBR", "cache"),
  refresh = FALSE,
  base_url = getOption("electedBR.base_url")
)

get_councilors(
  year = 2024L,
  state = NULL,
  municipality = NULL,
  party = NULL,
  include_alternates = FALSE,
  cache_dir = tools::R_user_dir("electedBR", "cache"),
  refresh = FALSE,
  base_url = getOption("electedBR.base_url")
)

consultar_eleitos(
  ano = 2024L,
  uf = NULL,
  municipio = NULL,
  cargo = NULL,
  partido = NULL,
  incluir_suplentes = FALSE,
  cache_dir = tools::R_user_dir("electedBR", "cache"),
  atualizar = FALSE,
  base_url = getOption("electedBR.base_url")
)

consultar_prefeitos(
  ano = 2024L,
  uf = NULL,
  municipio = NULL,
  partido = NULL,
  cache_dir = tools::R_user_dir("electedBR", "cache"),
  atualizar = FALSE,
  base_url = getOption("electedBR.base_url")
)

consultar_vereadores(
  ano = 2024L,
  uf = NULL,
  municipio = NULL,
  partido = NULL,
  incluir_suplentes = FALSE,
  cache_dir = tools::R_user_dir("electedBR", "cache"),
  atualizar = FALSE,
  base_url = getOption("electedBR.base_url")
)
```

## Arguments

- year:

  Election year; one of `elected_years$year`.

- state:

  One or more two-letter state abbreviations (`"PE"`, `"SP"`). `NULL`
  (the default) keeps every state.

- municipality:

  Municipality names (matched exactly, ignoring accents and case) or TSE
  municipality codes (not IBGE codes). Municipal offices only.

- office:

  One or more of `"mayor"`, `"deputy_mayor"`, `"councilor"`,
  `"senator"`, `"federal_deputy"`, `"state_deputy"` and
  `"district_deputy"`. `NULL` keeps every office in the year.

- party:

  Party abbreviations at the time of the election.

- include_alternates:

  Logical. Also return the candidates classified as `SUPLENTE`
  (alternate) in the TSE file. This is the classification at the poll,
  not a current substitution queue.

- cache_dir:

  Directory where the yearly files are stored. Defaults to the per-user
  cache directory returned by
  [`tools::R_user_dir()`](https://rdrr.io/r/tools/userdir.html).

- refresh:

  Logical. Download the file again even if a copy is cached.

- base_url:

  Optional base URL of a mirror hosting the files listed in
  [elected_years](https://strategicprojects.github.io/electedBR/reference/elected_years.md).
  Defaults to `getOption("electedBR.base_url")`; when `NULL`, the `url`
  column of
  [elected_years](https://strategicprojects.github.io/electedBR/reference/elected_years.md)
  is used.

- ano, uf, municipio, cargo, partido, incluir_suplentes, atualizar:

  Portuguese aliases of `year`, `state`, `municipality`, `office`,
  `party`, `include_alternates` and `refresh`. `cargo` also accepts the
  Portuguese labels `"PREFEITO"`, `"VICE-PREFEITO"`, `"VEREADOR"`,
  `"SENADOR"`, `"DEPUTADO FEDERAL"`, `"DEPUTADO ESTADUAL"` and
  `"DEPUTADO DISTRITAL"`.

## Value

A tibble with the columns documented in
[`normalize_elected()`](https://strategicprojects.github.io/electedBR/reference/normalize_elected.md):
`year`, `election_id`, `round`, `state`, `municipality_tse_id`,
`municipality`, `office`, `candidate_id`, `name`, `ballot_name`,
`party_at_election`, `election_status`, `votes` and `reference`. An
empty tibble with the same columns is returned when no row matches. The
attributes `source` (TSE dataset page) and `notice` are set.

## Details

The first call for a year downloads its Parquet file (a few megabytes)
into `cache_dir`; later calls read the local copy. Results describe who
was elected in the poll: they do not establish who currently holds
office nor current party membership. For sitting members of Congress use
[`get_deputies()`](https://strategicprojects.github.io/electedBR/reference/get_deputies.md)
and
[`get_senators()`](https://strategicprojects.github.io/electedBR/reference/get_deputies.md).

## See also

`get_mayors()`, `get_councilors()`,
[elected_years](https://strategicprojects.github.io/electedBR/reference/elected_years.md),
[`elected_clear_cache()`](https://strategicprojects.github.io/electedBR/reference/elected_clear_cache.md).

## Examples

``` r
if (FALSE) { # interactive()
# Mayors elected in Pernambuco in 2024
get_mayors(state = "PE", municipality = c("Recife", "Caruaru"),
           cache_dir = tempdir())

# Federal deputies elected in 2022, including alternates
get_elected(2022, state = "PE", office = "federal_deputy",
            include_alternates = TRUE, cache_dir = tempdir())

# Same query through the Portuguese alias
consultar_eleitos(2022, uf = "PE", cargo = "DEPUTADO FEDERAL",
                  cache_dir = tempdir())
}
```
