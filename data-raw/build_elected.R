## Builds the yearly files distributed by electedBR from the TSE open data.
##
## Input:  data-raw/tse/votacao_candidato_munzona_<year>.zip, downloaded from
##         https://dadosabertos.tse.jus.br/dataset/resultados-<year>
##         ("Votação nominal por município e zona", all states), and
##         data-raw/tse/consulta_cand_<year>.zip from
##         https://dadosabertos.tse.jus.br/dataset/candidatos-<year> ("Candidatos"),
##         used for the running mates. The TSE CDN (cdn.tse.jus.br) refuses
##         non-browser clients, so download the zips with a browser and drop
##         them in data-raw/tse/ (gitignored).
## Output: data-raw/parquet/elected_<year>.parquet = normalize_elected(votes,
##         candidates, include_alternates = TRUE): elected candidates, elected
##         running mates and TSE alternates.
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
keep_cand <- c("ANO_ELEICAO", "CD_ELEICAO", "NR_TURNO", "SG_UF", "SG_UE", "NM_UE",
               "CD_CARGO", "SQ_CANDIDATO", "NR_CANDIDATO", "NM_CANDIDATO",
               "NM_URNA_CANDIDATO", "SG_PARTIDO", "DS_SIT_TOT_TURNO")

read_tse_zip <- function(zip, year, cols) {
  tmp <- tempfile("tse_")
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)
  files <- unzip(zip, exdir = tmp)
  # One CSV per state, plus BR (nationwide offices: president) in general years.
  csvs <- files[grepl(sprintf("_%s_[A-Z]{2}\\.csv$", year), files)]
  stopifnot(length(csvs) >= 26)
  message("  ", basename(zip), ": ", length(csvs), " files")
  bind_rows(lapply(csvs, function(f) {
    read_delim(f, delim = ";", locale = locale(encoding = "latin1"),
               col_types = cols(.default = col_character()),
               col_select = all_of(cols), progress = FALSE, show_col_types = FALSE)
  }))
}

build_year <- function(year) {
  votes_zip <- file.path("data-raw", "tse", sprintf("votacao_candidato_munzona_%s.zip", year))
  cand_zip <- file.path("data-raw", "tse", sprintf("consulta_cand_%s.zip", year))
  out <- file.path("data-raw", "parquet", sprintf("elected_%s.parquet", year))
  stopifnot(file.exists(votes_zip), file.exists(cand_zip))
  dir.create(dirname(out), showWarnings = FALSE, recursive = TRUE)
  message(year)
  raw <- read_tse_zip(votes_zip, year, keep)
  cand <- read_tse_zip(cand_zip, year, keep_cand)
  stopifnot(all(raw$ANO_ELEICAO == as.character(year)), all(cand$ANO_ELEICAO == as.character(year)))
  x <- normalize_elected(raw, cand, include_alternates = TRUE)
  message("  ", nrow(raw), " vote records + ", nrow(cand), " candidates -> ", nrow(x), " rows")
  print(table(x$office, normalize_text(x$election_status) == "SUPLENTE"))
  # Every running mate must point to an elected head of ticket.
  mates <- x[!is.na(x$ticket_candidate_id), ]
  heads <- x$candidate_id[normalize_text(x$election_status) != "SUPLENTE"]
  stopifnot(all(mates$ticket_candidate_id %in% heads))
  nanoparquet::write_parquet(x, out, compression = "zstd")
  invisible(x)
}

years <- commandArgs(trailingOnly = TRUE)
if (!length(years))
  years <- sub("^votacao_candidato_munzona_(\\d{4})\\.zip$", "\\1",
               list.files("data-raw/tse", "^votacao_candidato_munzona_\\d{4}\\.zip$"))
for (y in sort(years)) build_year(y)
