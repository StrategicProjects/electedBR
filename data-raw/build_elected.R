## Builds the yearly files distributed by electedBR from the TSE open data.
##
## Input:  data-raw/tse/votacao_candidato_munzona_<year>.zip, downloaded from
##         https://dadosabertos.tse.jus.br/dataset/resultados-<year>
##         ("Votação nominal por município e zona", all states). The TSE CDN
##         (cdn.tse.jus.br) refuses non-browser clients, so download the zips
##         with a browser and drop them in data-raw/tse/ (gitignored).
## Output: data-raw/parquet/elected_<year>.parquet = normalize_elected(raw,
##         include_alternates = TRUE): elected candidates plus TSE alternates.
##
## Usage: Rscript data-raw/build_elected.R 2022 2024   (no args = every zip present)
## Afterwards upload the files (data-raw/upload_data.sh) and rebuild the index
## with Rscript data-raw/elected_years.R.

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
})
pkgload::load_all(".", quiet = TRUE)

keep <- c("ANO_ELEICAO", "CD_ELEICAO", "NR_TURNO", "SG_UF", "CD_MUNICIPIO",
          "NM_MUNICIPIO", "CD_CARGO", "DS_CARGO", "SQ_CANDIDATO", "NM_CANDIDATO",
          "NM_URNA_CANDIDATO", "SG_PARTIDO", "DS_SIT_TOT_TURNO", "QT_VOTOS_NOMINAIS")

build_year <- function(year) {
  zip <- file.path("data-raw", "tse", sprintf("votacao_candidato_munzona_%s.zip", year))
  out <- file.path("data-raw", "parquet", sprintf("elected_%s.parquet", year))
  stopifnot(file.exists(zip))
  dir.create(dirname(out), showWarnings = FALSE, recursive = TRUE)
  tmp <- tempfile("tse_")
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)
  files <- unzip(zip, exdir = tmp)
  # One CSV per state (plus BRASIL, which duplicates them): use the state files.
  csvs <- files[grepl(sprintf("_%s_[A-Z]{2}\\.csv$", year), files)]
  stopifnot(length(csvs) >= 26)
  message(year, ": reading ", length(csvs), " state files")
  raw <- bind_rows(lapply(csvs, function(f) {
    read_delim(f, delim = ";", locale = locale(encoding = "latin1"),
               col_types = cols(.default = col_character()),
               col_select = all_of(keep), progress = FALSE, show_col_types = FALSE)
  }))
  stopifnot(all(raw$ANO_ELEICAO == as.character(year)))
  x <- normalize_elected(raw, include_alternates = TRUE)
  message("  ", nrow(raw), " vote records -> ", nrow(x), " elected + alternates")
  print(table(x$office, normalize_text(x$election_status) == "SUPLENTE"))
  nanoparquet::write_parquet(x, out, compression = "zstd")
  invisible(x)
}

years <- commandArgs(trailingOnly = TRUE)
if (!length(years))
  years <- sub("^votacao_candidato_munzona_(\\d{4})\\.zip$", "\\1",
               list.files("data-raw/tse", "^votacao_candidato_munzona_\\d{4}\\.zip$"))
for (y in sort(years)) build_year(y)
