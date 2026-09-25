# Yearly files of elected candidates

Index of the Parquet files distributed by the package, one per election
year, with the URL they are downloaded from and the checksums used to
verify the download. Used internally by
[`get_elected()`](https://strategicprojects.github.io/electedBR/reference/get_elected.md);
the host can be overridden with the `electedBR.base_url` option or the
`base_url` argument.

## Usage

``` r
elected_years
```

## Format

A data frame with one row per year and the columns:

- year:

  Election year.

- kind:

  `"municipal"` (mayors, deputy mayors and councilors) or `"general"`
  (senators and federal, state and district deputies).

- file:

  File name (for example `elected_2024.parquet`).

- url:

  Download URL of the file.

- bytes:

  File size in bytes, used to check the download.

- md5:

  MD5 checksum of the file.

- rows:

  Number of rows (elected candidates plus alternates).

- built:

  Date on which the file was generated from the TSE data.

## Source

Derived from the TSE open data portal,
<https://dadosabertos.tse.jus.br/>; files hosted at
<https://huggingface.co/datasets/mlkwy/electedBR>.

## Details

Each file is the output of
[`normalize_elected()`](https://strategicprojects.github.io/electedBR/reference/normalize_elected.md)
with `include_alternates = TRUE` applied to the TSE *votação nominal por
município e zona* dataset of that year, so it holds both the elected
candidates and the alternates classified in the TSE file.

## Examples

``` r
elected_years
#>   year      kind                 file
#> 1 2018   general elected_2018.parquet
#> 2 2020 municipal elected_2020.parquet
#> 3 2022   general elected_2022.parquet
#> 4 2024 municipal elected_2024.parquet
#>                                                                                 url
#> 1 https://huggingface.co/datasets/mlkwy/electedBR/resolve/main/elected_2018.parquet
#> 2 https://huggingface.co/datasets/mlkwy/electedBR/resolve/main/elected_2020.parquet
#> 3 https://huggingface.co/datasets/mlkwy/electedBR/resolve/main/elected_2022.parquet
#> 4 https://huggingface.co/datasets/mlkwy/electedBR/resolve/main/elected_2024.parquet
#>   bytes  md5 rows built
#> 1    NA <NA>   NA  <NA>
#> 2    NA <NA>   NA  <NA>
#> 3    NA <NA>   NA  <NA>
#> 4    NA <NA>   NA  <NA>
```
