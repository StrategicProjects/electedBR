# Consolidate TSE vote records into the candidates elected

Turns the raw *votação nominal por município e zona* table published by
the Superior Electoral Court (TSE) into one row per elected candidate.
Votes are summed over electoral zones (and, for statewide offices, over
municipalities), the last round available for each candidate is kept,
and distinct elections held on the same date (for instance ordinary and
supplementary polls, which have different `CD_ELEICAO` codes) are never
merged. This is the function that builds the yearly files distributed
with the package; it is exported so that the same rules can be applied
to a fresh TSE download (for example the output of
`electionsBR::elections_tse()`).

## Usage

``` r
normalize_elected(data, include_alternates = FALSE)

normalizar_eleitos(dados, incluir_suplentes = FALSE)
```

## Arguments

- data:

  A data frame with the TSE vote-by-municipality-and-zone layout. The
  columns `ANO_ELEICAO`, `CD_ELEICAO`, `NR_TURNO`, `SG_UF`,
  `CD_MUNICIPIO`, `NM_MUNICIPIO`, `CD_CARGO`, `DS_CARGO`,
  `SQ_CANDIDATO`, `NM_CANDIDATO`, `NM_URNA_CANDIDATO`, `SG_PARTIDO`,
  `DS_SIT_TOT_TURNO` and `QT_VOTOS_NOMINAIS` are required
  (case-insensitive).

- include_alternates:

  Logical. Also keep candidates whose final status is `SUPLENTE`
  (alternate) in the TSE file. Senate ticket alternates have no votes of
  their own and are not covered; see
  [`get_senators()`](https://strategicprojects.github.io/electedBR/reference/get_deputies.md)
  for the alternates currently serving.

- dados, incluir_suplentes:

  Portuguese aliases of `data` and `include_alternates`.

## Value

A tibble with one row per candidate and election, with the columns
`year`, `election_id`, `round`, `state`, `municipality_tse_id`,
`municipality`, `office`, `candidate_id`, `name`, `ballot_name`,
`party_at_election`, `election_status`, `votes` and `reference`. For
statewide offices `municipality_tse_id` and `municipality` are `NA`.
`office` is one of `mayor`, `deputy_mayor`, `councilor`, `senator`,
`federal_deputy`, `state_deputy` or `district_deputy`; presidential and
gubernatorial rows are dropped.

## See also

[`get_elected()`](https://strategicprojects.github.io/electedBR/reference/get_elected.md)
for the ready-made yearly files.

## Examples

``` r
raw <- data.frame(
  ANO_ELEICAO = 2024, CD_ELEICAO = "619", NR_TURNO = 1, SG_UF = "PE",
  CD_MUNICIPIO = "25313", NM_MUNICIPIO = "RECIFE", CD_CARGO = "13",
  DS_CARGO = "Vereador", SQ_CANDIDATO = c("1", "1", "2"),
  NM_CANDIDATO = c("ANA", "ANA", "BRUNO"),
  NM_URNA_CANDIDATO = c("ANA", "ANA", "BRUNO"),
  SG_PARTIDO = c("PSB", "PSB", "PT"),
  DS_SIT_TOT_TURNO = c("ELEITO POR QP", "ELEITO POR QP", "SUPLENTE"),
  QT_VOTOS_NOMINAIS = c(100, 50, 200)
)
normalize_elected(raw)
#> # A tibble: 1 × 14
#>    year election_id round state municipality_tse_id municipality office   
#>   <int> <chr>       <int> <chr> <chr>               <chr>        <chr>    
#> 1  2024 619             1 PE    25313               RECIFE       councilor
#> # ℹ 7 more variables: candidate_id <chr>, name <chr>, ballot_name <chr>,
#> #   party_at_election <chr>, election_status <chr>, votes <dbl>,
#> #   reference <chr>
normalize_elected(raw, include_alternates = TRUE)
#> # A tibble: 2 × 14
#>    year election_id round state municipality_tse_id municipality office   
#>   <int> <chr>       <int> <chr> <chr>               <chr>        <chr>    
#> 1  2024 619             1 PE    25313               RECIFE       councilor
#> 2  2024 619             1 PE    25313               RECIFE       councilor
#> # ℹ 7 more variables: candidate_id <chr>, name <chr>, ballot_name <chr>,
#> #   party_at_election <chr>, election_status <chr>, votes <dbl>,
#> #   reference <chr>
```
