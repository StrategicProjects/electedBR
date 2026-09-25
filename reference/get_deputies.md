# Federal deputies and senators currently serving

Retrieves the members of the Chamber of Deputies and of the Federal
Senate currently in service, from the open data APIs of each house. The
lists include alternates who are serving; `mandate_role` tells
principals and alternates apart, independently of the service status.
Election results are a different question, answered by
[`get_elected()`](https://strategicprojects.github.io/electedBR/reference/get_elected.md).

## Usage

``` r
get_deputies(
  state = NULL,
  party = NULL,
  status = "serving",
  role = NULL,
  refresh = FALSE,
  max_age_hours = 6,
  cache_dir = tools::R_user_dir("electedBR", "cache")
)

get_senators(
  state = NULL,
  party = NULL,
  status = "serving",
  role = NULL,
  refresh = FALSE,
  max_age_hours = 6,
  cache_dir = tools::R_user_dir("electedBR", "cache")
)

consultar_deputados(
  uf = NULL,
  partido = NULL,
  situacao = "em_exercicio",
  condicao = NULL,
  atualizar = FALSE,
  validade_horas = 6,
  cache_dir = tools::R_user_dir("electedBR", "cache")
)

consultar_senadores(
  uf = NULL,
  partido = NULL,
  situacao = "em_exercicio",
  condicao = NULL,
  atualizar = FALSE,
  validade_horas = 6,
  cache_dir = tools::R_user_dir("electedBR", "cache")
)
```

## Arguments

- state:

  Two-letter state abbreviations; `NULL` keeps every state.

- party:

  Party abbreviations (current affiliation).

- status:

  Only `"serving"` is supported.

- role:

  `NULL`, or one or more of `"principal"`, `"alternate"` and
  `"unknown"`.

- refresh:

  Logical. Collect again even if a fresh cache exists.

- max_age_hours:

  Maximum age of the cache, in hours (default six).

- cache_dir:

  Cache directory; defaults to
  `tools::R_user_dir("electedBR", "cache")`.

- uf, partido, situacao, condicao, atualizar, validade_horas:

  Portuguese aliases of `state`, `party`, `status` (`"em_exercicio"`),
  `role` (`"titular"`, `"suplente"`, `"desconhecido"`), `refresh` and
  `max_age_hours`.

## Value

A tibble with the columns `person_id`, `source_id`, `name`, `state`,
`office`, `current_party`, `mandate_id`, `mandate_role`,
`mandate_role_raw`, `exercise_status`, `exercise_status_raw`,
`exercise_start`, `exercise_end`, `status_recorded_at`,
`source_updated_at`, `source`, `reference` and `retrieved_at`. Columns
ending in `_raw` keep the label used by the source; `person_id` is
namespaced (`camara:204379`, `senado:5322`) and is not a TSE identifier.

## Details

The Chamber list is paginated and the electoral condition of each deputy
comes from a detail request per deputy, so the first call without
`state` issues several hundred requests; results are cached for
`max_age_hours` hours in `cache_dir`, and every completed collection is
also kept as an immutable snapshot under `cache_dir/snapshots/`. A
network or schema failure raises an error rather than silently returning
expired data.

## See also

[`get_service_history()`](https://strategicprojects.github.io/electedBR/reference/get_service_history.md)
for the status records and service periods of one member.

## Examples

``` r
if (FALSE) { # interactive()
get_senators(state = "PE", cache_dir = tempdir())
get_deputies(state = c("PE", "PB"), role = "alternate", cache_dir = tempdir())
consultar_senadores(uf = "PE", cache_dir = tempdir())
}
```
