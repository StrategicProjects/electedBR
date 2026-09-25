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

# TSE-like candidates records for the same municipality: the mayoral ticket
# (head 1, running mate 9) and a losing ticket.
cand_fixture <- function() {
  data.frame(ANO_ELEICAO = "2024", CD_ELEICAO = "619", NR_TURNO = 1, SG_UF = "PE",
    SG_UE = "25313", NM_UE = "RECIFE", CD_CARGO = c("11", "12", "11", "12", "13"),
    SQ_CANDIDATO = c("1", "9", "5", "6", "2"), NR_CANDIDATO = c("40", "40", "13", "13", "40123"),
    NM_CANDIDATO = c("A", "V", "E", "F", "B"), NM_URNA_CANDIDATO = c("A", "V", "E", "F", "B"),
    SG_PARTIDO = c("PSB", "PC do B", "PT", "PT", "PT"),
    DS_SIT_TOT_TURNO = c("ELEITO", "ELEITO", "N\u00c3O ELEITO", "N\u00c3O ELEITO", "ELEITO POR QP"),
    stringsAsFactors = FALSE)
}

# Office-holding events: the mayor (1) resigns and the running mate (9) takes over.
events_fixture <- function() {
  data.frame(year = 2024L, candidate_id = "1", name = "A", office = "mayor", state = "PE",
    municipality_tse_id = "25313", event = "resignation", date = "2026-04-02",
    successor_candidate_id = "9", successor_name = "V", successor_date = "2026-04-06",
    source = "https://example.org/record", notes = "", stringsAsFactors = FALSE)
}

# Writes a yearly file into `dir` so that get_elected() works offline.
seed_cache <- function(dir, year = 2024L, data = tse_fixture(), candidates = cand_fixture()) {
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  x <- normalize_elected(data, candidates, include_alternates = TRUE)
  nanoparquet::write_parquet(x, file.path(dir, sprintf("elected_%d.parquet", year)))
  invisible(dir)
}
