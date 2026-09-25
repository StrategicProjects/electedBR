# Candidates elected in Brazilian elections

Returns the candidates elected (and optionally the alternates) in a
Brazilian election year, from the yearly files derived from the TSE open
data and hosted by the package (see
[elected_years](https://strategicprojects.github.io/electedBR/reference/elected_years.md)).
Municipal offices (mayor, vice mayor, councilor) are available for
municipal election years (2020, 2024, ...) and president, vice
president, governors, vice governors, senators and federal, state and
district deputies for general election years (2018, 2022, ...).

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
  as_of = NULL,
  events = NULL,
  base_url = getOption("electedBR.base_url")
)

get_mayors(
  year = 2024L,
  state = NULL,
  municipality = NULL,
  party = NULL,
  cache_dir = tools::R_user_dir("electedBR", "cache"),
  refresh = FALSE,
  as_of = NULL,
  events = NULL,
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
  data_referencia = NULL,
  eventos = NULL,
  base_url = getOption("electedBR.base_url")
)

consultar_prefeitos(
  ano = 2024L,
  uf = NULL,
  municipio = NULL,
  partido = NULL,
  cache_dir = tools::R_user_dir("electedBR", "cache"),
  atualizar = FALSE,
  data_referencia = NULL,
  eventos = NULL,
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
  (the default) keeps every state. President and vice president rows
  carry no state and are dropped when `state` is given.

- municipality:

  Municipality names (matched exactly, ignoring accents and case) or TSE
  municipality codes (not IBGE codes). Municipal offices only.

- office:

  One or more of `"president"`, `"vice_president"`, `"governor"`,
  `"vice_governor"`, `"senator"`, `"federal_deputy"`, `"state_deputy"`,
  `"district_deputy"`, `"mayor"`, `"vice_mayor"` and `"councilor"`.
  `NULL` keeps every office in the year. Running mates come from the TSE
  candidates file, have `votes = NA` and are linked to the head of their
  ticket by `ticket_candidate_id`.

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

- as_of:

  Optional date (or string convertible with
  [`as.Date()`](https://rdrr.io/r/base/as.Date.html)). When given, the
  office-holding events dated on or before it are applied and the
  columns `status_as_of`, `status_date`, `office_as_of` and
  `status_source` are added: `status_as_of` is the latest event recorded
  for the official (`resignation`, `death`, `removal`, `leave`,
  `return`), `succession` for a running mate who took over (with
  `office_as_of` set to the office assumed) or `no_change_recorded`.

- events:

  Optional events table with the columns of
  [`get_officeholding_events()`](https://strategicprojects.github.io/electedBR/reference/get_officeholding_events.md),
  used instead of downloading it.

- base_url:

  Optional base URL of a mirror hosting the files listed in
  [elected_years](https://strategicprojects.github.io/electedBR/reference/elected_years.md).
  Defaults to `getOption("electedBR.base_url")`; when `NULL`, the `url`
  column of
  [elected_years](https://strategicprojects.github.io/electedBR/reference/elected_years.md)
  is used.

- ano, uf, municipio, cargo, partido, incluir_suplentes, atualizar,
  data_referencia, eventos:

  Portuguese aliases of `year`, `state`, `municipality`, `office`,
  `party`, `include_alternates`, `refresh`, `as_of` and `events`.
  `cargo` also accepts the Portuguese labels `"PRESIDENTE"`,
  `"VICE-PRESIDENTE"`, `"GOVERNADOR"`, `"VICE-GOVERNADOR"`, `"SENADOR"`,
  `"DEPUTADO FEDERAL"`, `"DEPUTADO ESTADUAL"`, `"DEPUTADO DISTRITAL"`,
  `"PREFEITO"`, `"VICE-PREFEITO"` and `"VEREADOR"`.

## Value

A tibble with the columns documented in
[`normalize_elected()`](https://strategicprojects.github.io/electedBR/reference/normalize_elected.md):
`year`, `election_id`, `round`, `state`, `municipality_tse_id`,
`municipality`, `office`, `candidate_id`, `ticket_candidate_id`, `name`,
`ballot_name`, `party_at_election`, `election_status`, `votes` and
`reference`, plus the four `*_as_of` columns when `as_of` is given. An
empty tibble with the same columns is returned when no row matches. The
attributes `source` (TSE dataset page) and `notice` are set.

## Details

The first call for a year downloads its Parquet file (about 1 MB for a
general election, up to 25 MB for a municipal one, see
`elected_years$bytes`) into `cache_dir`; later calls read the local
copy. Results describe who was elected in the poll: they do not
establish who currently holds office nor current party membership. For
sitting members of Congress use
[`get_deputies()`](https://strategicprojects.github.io/electedBR/reference/get_deputies.md)
and
[`get_senators()`](https://strategicprojects.github.io/electedBR/reference/get_deputies.md);
for mayors and governors, `as_of` applies the curated
[`get_officeholding_events()`](https://strategicprojects.github.io/electedBR/reference/get_officeholding_events.md)
table (resignations, deaths, removals, leaves and successions), which
records changes but does not prove that an official without a record is
in office.

## See also

`get_mayors()`, `get_councilors()`,
[elected_years](https://strategicprojects.github.io/electedBR/reference/elected_years.md),
[`get_officeholding_events()`](https://strategicprojects.github.io/electedBR/reference/get_officeholding_events.md),
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

# Governor and vice governor of Pernambuco elected in 2022
get_elected(2022, state = "PE", office = c("governor", "vice_governor"),
            cache_dir = tempdir())

# Who holds the Recife mayoralty on a given date, after the 2026 resignation
get_mayors(state = "PE", municipality = "Recife", as_of = "2026-06-01",
           cache_dir = tempdir())

# Same query through the Portuguese alias
consultar_eleitos(2022, uf = "PE", cargo = "DEPUTADO FEDERAL",
                  cache_dir = tempdir())
}
```
