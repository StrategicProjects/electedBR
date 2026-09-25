# Raw TSE-like vote records (municipal election, one municipality, two zones
# for the mayor) used across the tests.
tse_fixture <- function() {
  data.frame(ANO_ELEICAO = "2024", CD_ELEICAO = "619", NR_TURNO = 1,
    SG_UF = "PE", CD_MUNICIPIO = "25313", NM_MUNICIPIO = "RECIFE",
    CD_CARGO = c("11", "11", "13", "13", "13"),
    DS_CARGO = c("Prefeito", "Prefeito", "Vereador", "Vereador", "Vereador"),
    SQ_CANDIDATO = c("1", "1", "2", "3", "4"),
    NM_CANDIDATO = c("A", "A", "B", "C", "D"),
    NM_URNA_CANDIDATO = c("A", "A", "B", "C", "D"),
    SG_PARTIDO = c("PSB", "PSB", "PT", "MDB", "PSD"),
    DS_SIT_TOT_TURNO = c("ELEITO", "ELEITO", "ELEITO POR QP", "SUPLENTE",
                         "ELEITO POR MÉDIA"),
    QT_VOTOS_NOMINAIS = c(100, 50, 30, 90, 20),
    stringsAsFactors = FALSE)
}

# Writes a yearly file into `dir` so that get_elected() works offline.
seed_cache <- function(dir, year = 2024L, data = tse_fixture()) {
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  x <- normalize_elected(data, include_alternates = TRUE)
  nanoparquet::write_parquet(x, file.path(dir, sprintf("elected_%d.parquet", year)))
  invisible(dir)
}
