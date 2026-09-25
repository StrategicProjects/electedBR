# Office-holding events for elected officials

A curated table of changes in office holding after the election (an
official who resigned, died, was removed or took leave, and who
succeeded them), for the offices covered by
[`get_elected()`](https://strategicprojects.github.io/electedBR/reference/get_elected.md)
that have no official API of sitting members: mayors, governors and
their deputies. It is maintained in the package repository, served from
the same host as the yearly files and refreshed on demand, not on a
schedule; an official absent from the table has simply not been
recorded, which is not evidence of being in office. Every row cites its
source. Contributions are welcome at
<https://github.com/StrategicProjects/electedBR>.

## Usage

``` r
get_officeholding_events(
  events = NULL,
  refresh = FALSE,
  max_age_hours = 24,
  cache_dir = elected_cache_dir(),
  base_url = getOption("electedBR.base_url")
)

consultar_eventos_exercicio(
  eventos = NULL,
  atualizar = FALSE,
  validade_horas = 24,
  cache_dir = elected_cache_dir(),
  base_url = getOption("electedBR.base_url")
)
```

## Arguments

- events:

  Optional data frame with the same columns, used instead of downloading
  (for example a local copy under review).

- refresh:

  Logical. Collect again even if a fresh cache exists.

- max_age_hours:

  Maximum age of the cache, in hours (default six).

- cache_dir:

  Cache directory; see
  [`elected_cache_dir()`](https://strategicprojects.github.io/electedBR/reference/elected_cache_dir.md).

- base_url:

  Optional base URL of a mirror hosting the files listed in
  [elected_years](https://strategicprojects.github.io/electedBR/reference/elected_years.md).
  Defaults to `getOption("electedBR.base_url")`; when `NULL`, the `url`
  column of
  [elected_years](https://strategicprojects.github.io/electedBR/reference/elected_years.md)
  is used.

- eventos, atualizar, validade_horas:

  Portuguese aliases of `events`, `refresh` and `max_age_hours`.

## Value

A tibble with the columns `year` and `candidate_id` (identifying the
official in the yearly file of that election), `name`, `office`,
`state`, `municipality_tse_id`, `event` (`resignation`, `death`,
`removal`, `leave` or `return`), `date`, `successor_candidate_id`,
`successor_name`, `successor_date` (when the successor took office),
`source` (URL of an official or press record) and `notes`, plus
`retrieved_at`.

## See also

[`get_elected()`](https://strategicprojects.github.io/electedBR/reference/get_elected.md),
whose `as_of` argument applies these events.

## Examples

``` r
if (FALSE) { # interactive()
get_officeholding_events(cache_dir = tempdir())
}
```
