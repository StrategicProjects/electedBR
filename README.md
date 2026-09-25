# electedBR <img src="man/figures/logo.svg" align="right" height="139" alt="electedBR hex logo" />

<!-- badges: start -->
[![Project Status: Active](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
![CRAN_Status_Badge](https://www.r-pkg.org/badges/version/electedBR)
![License](https://img.shields.io/badge/license-GPL--3-blue.svg)
[![R-CMD-check](https://github.com/StrategicProjects/electedBR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/StrategicProjects/electedBR/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/StrategicProjects/electedBR/graph/badge.svg)](https://app.codecov.io/gh/StrategicProjects/electedBR)
[![Documentation](https://img.shields.io/badge/docs-pkgdown-blue)](https://strategicprojects.github.io/electedBR/)
<!-- badges: end -->

electedBR answers two different questions about Brazilian politics and keeps
them apart:

* **Who was elected?** Candidates elected in municipal (2020, 2024) and
  general (2018, 2022) elections, consolidated from the open data of the
  Superior Electoral Court ([TSE](https://dadosabertos.tse.jus.br/)) into one
  small Parquet file per year, hosted on
  [Hugging Face](https://huggingface.co/datasets/mlkwy/electedBR).
* **Who is serving now?** Federal deputies and senators currently in service,
  from the open data APIs of the
  [Chamber of Deputies](https://dadosabertos.camara.leg.br/) and the
  [Federal Senate](https://www12.senado.leg.br/dados-abertos), plus the
  official service history of each member.

Every function returns a tibble with English column names, and every function
has a Portuguese alias.

## Installation

``` r
# install.packages("remotes")
remotes::install_github("StrategicProjects/electedBR")
```

## Election results

``` r
library(electedBR)

# Mayors elected in Pernambuco in 2024
get_mayors(state = "PE", municipality = c("Recife", "Caruaru"))
consultar_prefeitos(uf = "PE", municipio = c("Recife", "Caruaru"))

# Councilors, by party, including the alternates classified by the TSE
get_councilors(state = "PE", municipality = "Recife", party = c("PT", "PSB"),
               include_alternates = TRUE)

# General elections: statewide offices
get_elected(2022, state = "PE", office = "federal_deputy")
get_elected(2022, state = "DF", office = "district_deputy")
consultar_eleitos(2022, uf = "PE", cargo = "SENADOR")
```

The first query for a year downloads its file (about 1 MB for a general
election, up to 25 MB for a municipal one) into
`tools::R_user_dir("electedBR", "cache")`; later queries read the local
copy. `elected_years` lists the files, their checksums and build dates.

Columns: `year`, `election_id`, `round`, `state`, `municipality_tse_id`,
`municipality`, `office`, `candidate_id`, `name`, `ballot_name`,
`party_at_election`, `election_status`, `votes`, `reference`.

What the results mean:

* Votes are summed over electoral zones and, for statewide offices, over
  municipalities; the municipal columns are then `NA` and `municipality`
  cannot be used as a filter.
* The last round available for each candidate is kept, and elections with
  different TSE codes (ordinary and supplementary polls) are never merged.
* `include_alternates = TRUE` adds the `SUPLENTE` rows of the TSE file. This
  is the classification at the poll, not a current substitution queue, and
  Senate ticket alternates (who have no votes of their own) are not covered.
* Municipality names are matched exactly, ignoring accents and case; codes
  are TSE codes, not IBGE codes. `party_at_election` is the party at the
  time of the election.
* Deputy mayors run on the mayor's ticket and have no votes of their own in
  the TSE files, so `office = "deputy_mayor"` returns no rows; presidents and
  governors are not covered.
* Being elected does not mean being in office today: use the functions
  below for that.

`normalize_elected()` is the function that builds the yearly files and is
exported, so the same rules can be applied to a fresh TSE download (for
example from `electionsBR`).

## Sitting members of Congress

``` r
get_senators(state = "PE")
get_deputies(state = c("PE", "PB"), party = "PSB", role = "alternate")
consultar_deputados(uf = "PE", condicao = "suplente")

senators <- get_senators(state = "PE")
get_service_history(senators$person_id[[1]])
consultar_historico_exercicio("camara:204379")
```

* `mandate_role` (`principal`, `alternate`, `unknown`) is the electoral
  condition; `exercise_status` is the service status. Alternates currently
  serving are listed. Columns ending in `_raw` keep the source label.
* `person_id` is namespaced by house (`camara:204379`, `senado:5322`); it is
  not a TSE identifier and no matching by name is attempted between sources.
* The Senate publishes service periods (`record_type = "service_period"`,
  with `exercise_start` and `exercise_end`); the Chamber publishes status
  records (`record_type = "status_record"`, with `record_at`). The package
  preserves the difference instead of inferring dates.
* Results are cached for six hours (`max_age_hours`, `refresh = TRUE`), and
  every completed collection is kept as an immutable snapshot under
  `cache_dir/snapshots/`. A network or schema failure raises an error rather
  than returning expired data.
* Without `state`, `get_deputies()` issues one detail request per deputy;
  the first national call takes a few minutes.

| English | Portuguese |
|---|---|
| `get_elected()`, `get_mayors()`, `get_councilors()` | `consultar_eleitos()`, `consultar_prefeitos()`, `consultar_vereadores()` |
| `get_deputies()`, `get_senators()` | `consultar_deputados()`, `consultar_senadores()` |
| `get_service_history()` | `consultar_historico_exercicio()` |
| `normalize_elected()`, `elected_clear_cache()` | `normalizar_eleitos()`, `limpar_cache_eleitos()` |
| `year`, `state`, `municipality`, `office`, `party` | `ano`, `uf`, `municipio`, `cargo`, `partido` |
| `include_alternates`, `refresh`, `max_age_hours` | `incluir_suplentes`, `atualizar`, `validade_horas` |
| `status = "serving"`, `role = "principal"/"alternate"` | `situacao = "em_exercicio"`, `condicao = "titular"/"suplente"` |

Both interfaces return the same tibbles, with English columns.

## Data sources

* TSE, *Resultados*: <https://dadosabertos.tse.jus.br/dataset/resultados-2024>
  (and 2018, 2020, 2022). Yearly files:
  <https://huggingface.co/datasets/mlkwy/electedBR>.
* Chamber of Deputies open data API: <https://dadosabertos.camara.leg.br/swagger/api.html>
* Federal Senate open data: <https://legis.senado.leg.br/dadosabertos/>

## Related packages

* [electionsBR](https://cran.r-project.org/package=electionsBR) downloads the raw TSE files
  (candidates, votes by zone and section, coalitions, assets).
* [congressbr](https://github.com/duarteguilherme/congressbr) wraps the Chamber
  and Senate APIs for bills, votes and speeches.

## Citation

``` r
citation("electedBR")
```

## Code of conduct

Please note that this project is released with a
[Contributor Code of Conduct](CODE_OF_CONDUCT.md). By participating you agree
to abide by its terms.
