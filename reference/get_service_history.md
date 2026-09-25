# Service history of a deputy or senator

Returns the official records about the service of one member of
Congress, identified by the `person_id` returned by
[`get_deputies()`](https://strategicprojects.github.io/electedBR/reference/get_deputies.md)
or
[`get_senators()`](https://strategicprojects.github.io/electedBR/reference/get_deputies.md).
The two houses publish different things and the difference is preserved
rather than reconciled:

## Usage

``` r
get_service_history(
  person_id,
  refresh = FALSE,
  max_age_hours = 6,
  cache_dir = elected_cache_dir()
)

consultar_historico_exercicio(
  id_pessoa,
  atualizar = FALSE,
  validade_horas = 6,
  cache_dir = elected_cache_dir()
)
```

## Arguments

- person_id:

  A single id such as `"camara:204379"` or `"senado:5322"`.

- refresh:

  Logical. Collect again even if a fresh cache exists.

- max_age_hours:

  Maximum age of the cache, in hours (default six).

- cache_dir:

  Cache directory; see
  [`elected_cache_dir()`](https://strategicprojects.github.io/electedBR/reference/elected_cache_dir.md).

- id_pessoa, atualizar, validade_horas:

  Portuguese aliases of `person_id`, `refresh` and `max_age_hours`.

## Value

A tibble with the columns `person_id`, `name`, `state`, `office`,
`mandate_id`, `mandate_role`, `mandate_role_raw`, `exercise_status`,
`exercise_status_raw`, `party_at_record`, `record_type`, `record_at`,
`exercise_start`, `exercise_end`, `description`, `source`,
`source_updated_at` and `retrieved_at`.

## Details

- Chamber (`camara:`): `record_type = "status_record"`, one row per
  status record with `record_at`, the situation and the party at that
  moment. Registry or party changes are not turned into starts or ends
  of service, so `exercise_start` and `exercise_end` are `NA`.

- Senate (`senado:`): `record_type = "service_period"`, one row per
  official period of each mandate, with `exercise_start` and
  `exercise_end`. An open period is not by itself evidence of current
  service; use
  [`get_senators()`](https://strategicprojects.github.io/electedBR/reference/get_deputies.md)
  for that.

## Examples

``` r
if (FALSE) { # interactive()
senators <- get_senators(state = "PE", cache_dir = tempdir())
get_service_history(senators$person_id[[1]], cache_dir = tempdir())
get_service_history("camara:204379", cache_dir = tempdir())
}
```
