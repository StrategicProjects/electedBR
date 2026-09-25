# Getting started with electedBR

electedBR answers two different questions about Brazilian politics and
keeps them apart:

- **Who was elected?**
  [`get_elected()`](https://strategicprojects.github.io/electedBR/reference/get_elected.md)
  reads the candidates elected in a given year from yearly files
  consolidated from the open data of the Superior Electoral Court (TSE).
- **Who is serving now?**
  [`get_deputies()`](https://strategicprojects.github.io/electedBR/reference/get_deputies.md)
  and
  [`get_senators()`](https://strategicprojects.github.io/electedBR/reference/get_deputies.md)
  query the open data APIs of the Chamber of Deputies and the Federal
  Senate for the members currently in service, and
  [`get_service_history()`](https://strategicprojects.github.io/electedBR/reference/get_service_history.md)
  returns the official records of one member.

Every function returns a tibble with English column names, and every
function has a Portuguese alias
([`consultar_eleitos()`](https://strategicprojects.github.io/electedBR/reference/get_elected.md),
[`consultar_senadores()`](https://strategicprojects.github.io/electedBR/reference/get_deputies.md),
…).

``` r

library(electedBR)
```

## Election results

The yearly files are listed in `elected_years`. The first query for a
year downloads its file (1 to 25 MB) into the cache directory, which by
default is a folder under
[`tempdir()`](https://rdrr.io/r/base/tempfile.html); set the
`electedBR.cache_dir` option or the `ELECTEDBR_CACHE_DIR` environment
variable to keep the files between sessions (see
[`?elected_cache_dir`](https://strategicprojects.github.io/electedBR/reference/elected_cache_dir.md)).
Here we use an explicit temporary directory.

``` r

elected_years[, c("year", "kind", "rows", "built")]
#>   year      kind   rows      built
#> 1 2018   general  20226 2026-09-25
#> 2 2020 municipal 381334 2026-09-25
#> 3 2022   general  16324 2026-09-25
#> 4 2024 municipal 306023 2026-09-25
cache <- tempdir()
```

Mayors elected in two municipalities of Pernambuco in 2024:

``` r

get_mayors(state = "PE", municipality = c("Recife", "Caruaru"), cache_dir = cache)
#> Downloading elected_2024.parquet from https://huggingface.co/datasets/mlkwy/electedBR/resolve/main/elected_2024.parquet
#> # A tibble: 2 × 15
#>    year election_id round state municipality_tse_id municipality office
#>   <int> <chr>       <int> <chr> <chr>               <chr>        <chr> 
#> 1  2024 619             1 PE    23817               CARUARU      mayor 
#> 2  2024 619             1 PE    25313               RECIFE       mayor 
#> # ℹ 8 more variables: candidate_id <chr>, ticket_candidate_id <chr>,
#> #   name <chr>, ballot_name <chr>, party_at_election <chr>,
#> #   election_status <chr>, votes <dbl>, reference <chr>
```

Municipalities are matched by name (ignoring accents and case) or by
their TSE code. Councilors of a municipality, by party, with the
alternates classified by the TSE:

``` r

recife <- get_councilors(state = "PE", municipality = "Recife",
                         include_alternates = TRUE, cache_dir = cache)
table(recife$election_status)
#> 
#> ELEITO POR MÉDIA    ELEITO POR QP         SUPLENTE 
#>                6               31              356
```

General elections (2018, 2022) hold the statewide and nationwide
offices; votes are summed over every municipality (and, for president,
every state) and the municipal columns are `NA`. Running mates have no
votes of their own and are linked to the head of their ticket by
`ticket_candidate_id`:

``` r

pe22 <- get_elected(2022, state = "PE", office = c("governor", "vice_governor"),
                    cache_dir = cache)
#> Downloading elected_2022.parquet from https://huggingface.co/datasets/mlkwy/electedBR/resolve/main/elected_2022.parquet
pe22[, c("office", "candidate_id", "ticket_candidate_id", "ballot_name",
         "party_at_election", "votes")]
#> # A tibble: 2 × 6
#>   office  candidate_id ticket_candidate_id ballot_name party_at_election   votes
#>   <chr>   <chr>        <chr>               <chr>       <chr>               <dbl>
#> 1 govern… 170001604087 <NA>                RAQUEL LYRA PSDB              3113415
#> 2 vice_g… 170001728608 170001604087        PRISCILA K… CIDADANIA              NA
```

``` r

get_elected(2022, state = "PE", office = "senator", cache_dir = cache)
#> # A tibble: 1 × 15
#>    year election_id round state municipality_tse_id municipality office 
#>   <int> <chr>       <int> <chr> <chr>               <chr>        <chr>  
#> 1  2022 546             1 PE    <NA>                <NA>         senator
#> # ℹ 8 more variables: candidate_id <chr>, ticket_candidate_id <chr>,
#> #   name <chr>, ballot_name <chr>, party_at_election <chr>,
#> #   election_status <chr>, votes <dbl>, reference <chr>
```

The Portuguese aliases accept the Portuguese office labels and return
exactly the same tibble:

``` r

identical(
  consultar_eleitos(2022, uf = "PE", cargo = "SENADOR", cache_dir = cache),
  get_elected(2022, state = "PE", office = "senator", cache_dir = cache)
)
#> [1] TRUE
```

Results describe the poll: `party_at_election` is the party at the time
of the election, and a candidate elected in 2022 is not necessarily in
office today.

### Who holds the office on a given date?

Mayors and governors have no official API of sitting members. The
package keeps a small curated table of office-holding events
(resignations, deaths, removals, leaves and successions), each row
citing its source, served next to the yearly files and updated on
demand. `as_of` applies it. In Recife, the mayor elected in 2024
resigned on 2026-04-02 to run for governor and the vice mayor took
office on 2026-04-06:

``` r

recife_ticket <- get_elected(state = "PE", municipality = "Recife",
                             office = c("mayor", "vice_mayor"),
                             as_of = "2026-06-01", cache_dir = cache)
recife_ticket[, c("office", "ballot_name", "status_as_of", "status_date",
                  "office_as_of")]
#> # A tibble: 2 × 5
#>   office     ballot_name    status_as_of status_date office_as_of
#>   <chr>      <chr>          <chr>        <date>      <chr>       
#> 1 mayor      JOÃO CAMPOS    resignation  2026-04-02  mayor       
#> 2 vice_mayor VICTOR MARQUES succession   2026-04-06  mayor
```

`no_change_recorded` means exactly that: nothing has been recorded for
the official, which is not evidence of being in office. The table
itself:

``` r

get_officeholding_events(cache_dir = cache)[, c("name", "office", "event", "date",
                                                "successor_name", "successor_date")]
#> # A tibble: 1 × 6
#>   name                     office event date       successor_name successor_date
#>   <chr>                    <chr>  <chr> <date>     <chr>          <date>        
#> 1 JOÃO HENRIQUE DE ANDRAD… mayor  resi… 2026-04-02 VICTOR MARQUE… 2026-04-06
```

## Sitting members of Congress

The current composition comes from the official APIs and is cached for
six hours. `mandate_role` (principal or alternate) is kept separate from
`exercise_status`, so alternates currently serving are listed.

``` r

pe <- get_senators(state = "PE", cache_dir = cache)
pe[, c("person_id", "name", "current_party", "mandate_role", "exercise_start")]
#> # A tibble: 3 × 5
#>   person_id   name            current_party mandate_role exercise_start
#>   <chr>       <chr>           <chr>         <chr>        <date>        
#> 1 senado:5917 Fernando Dueire PSD           alternate    2023-09-04    
#> 2 senado:5008 Humberto Costa  PT            principal    2019-02-01    
#> 3 senado:6338 Teresa Leitão   PT            principal    2023-02-01
```

`person_id` is namespaced by house (`senado:`, `camara:`) and is the key
for the service history. The Senate publishes service periods; the
Chamber publishes status records, and the package does not turn one into
the other.

``` r

h <- get_service_history(pe$person_id[[1]], cache_dir = cache)
h[, c("mandate_id", "record_type", "exercise_start", "exercise_end", "description")]
#> # A tibble: 2 × 5
#>   mandate_id record_type    exercise_start exercise_end description       
#>   <chr>      <chr>          <date>         <date>       <chr>             
#> 1 526        service_period 2022-12-07     2023-09-04   Retorno do titular
#> 2 526        service_period 2023-09-04     NA           <NA>
```

[`get_deputies()`](https://strategicprojects.github.io/electedBR/reference/get_deputies.md)
works the same way; without `state` it issues one detail request per
deputy, so the first national call takes a few minutes.

## Provenance and caching

- Every tibble from
  [`get_elected()`](https://strategicprojects.github.io/electedBR/reference/get_elected.md)
  carries a `source` attribute with the TSE dataset page, and the
  parliamentary tables carry the API URL in `source` and the collection
  time in `retrieved_at` (UTC).
- Yearly files are verified against the size and MD5 in `elected_years`.
  `refresh = TRUE` downloads again;
  [`elected_clear_cache()`](https://strategicprojects.github.io/electedBR/reference/elected_clear_cache.md)
  empties the cache.
- Parliamentary queries keep an immutable snapshot of every completed
  collection under `cache_dir/snapshots/`; a network failure raises an
  error instead of returning expired data.

&nbsp;

    #> Built on 2026-09-25
