#' Consolidate TSE vote records into the candidates elected
#'
#' Turns the raw *votação nominal por município e zona* table published by the
#' Superior Electoral Court (TSE) into one row per elected candidate. Votes are
#' summed over electoral zones (and, for statewide offices, over
#' municipalities), the last round available for each candidate is kept, and
#' distinct elections held on the same date (for instance ordinary and
#' supplementary polls, which have different `CD_ELEICAO` codes) are never
#' merged. This is the function that builds the yearly files distributed with
#' the package; it is exported so that the same rules can be applied to a
#' fresh TSE download (for example the output of `electionsBR::elections_tse()`).
#'
#' @param data A data frame with the TSE vote-by-municipality-and-zone layout.
#'   The columns `ANO_ELEICAO`, `CD_ELEICAO`, `NR_TURNO`, `SG_UF`,
#'   `CD_MUNICIPIO`, `NM_MUNICIPIO`, `CD_CARGO`, `DS_CARGO`, `SQ_CANDIDATO`,
#'   `NM_CANDIDATO`, `NM_URNA_CANDIDATO`, `SG_PARTIDO`, `DS_SIT_TOT_TURNO` and
#'   `QT_VOTOS_NOMINAIS` are required (case-insensitive).
#' @param include_alternates Logical. Also keep candidates whose final status
#'   is `SUPLENTE` (alternate) in the TSE file. Senate ticket alternates have no
#'   votes of their own and are not covered; see [get_senators()] for the
#'   alternates currently serving.
#' @return A tibble with one row per candidate and election, with the columns
#'   `year`, `election_id`, `round`, `state`, `municipality_tse_id`,
#'   `municipality`, `office`, `candidate_id`, `name`, `ballot_name`,
#'   `party_at_election`, `election_status`, `votes` and `reference`. For
#'   statewide offices `municipality_tse_id` and `municipality` are `NA`.
#'   `office` is one of `mayor`, `deputy_mayor`, `councilor`, `senator`,
#'   `federal_deputy`, `state_deputy` or `district_deputy`; presidential and
#'   gubernatorial rows are dropped.
#' @seealso [get_elected()] for the ready-made yearly files.
#' @examples
#' raw <- data.frame(
#'   ANO_ELEICAO = 2024, CD_ELEICAO = "619", NR_TURNO = 1, SG_UF = "PE",
#'   CD_MUNICIPIO = "25313", NM_MUNICIPIO = "RECIFE", CD_CARGO = "13",
#'   DS_CARGO = "Vereador", SQ_CANDIDATO = c("1", "1", "2"),
#'   NM_CANDIDATO = c("ANA", "ANA", "BRUNO"),
#'   NM_URNA_CANDIDATO = c("ANA", "ANA", "BRUNO"),
#'   SG_PARTIDO = c("PSB", "PSB", "PT"),
#'   DS_SIT_TOT_TURNO = c("ELEITO POR QP", "ELEITO POR QP", "SUPLENTE"),
#'   QT_VOTOS_NOMINAIS = c(100, 50, 200)
#' )
#' normalize_elected(raw)
#' normalize_elected(raw, include_alternates = TRUE)
#' @export
normalize_elected <- function(data, include_alternates = FALSE) {
  if (!is.data.frame(data))
    stop("`data` must be a data frame with the TSE vote layout.", call. = FALSE)
  .check_flag(include_alternates, "include_alternates")
  names(data) <- toupper(names(data))
  required <- c("ANO_ELEICAO", "CD_ELEICAO", "NR_TURNO", "SG_UF", "CD_MUNICIPIO",
                "NM_MUNICIPIO", "CD_CARGO", "DS_CARGO", "SQ_CANDIDATO",
                "NM_CANDIDATO", "NM_URNA_CANDIDATO", "SG_PARTIDO",
                "DS_SIT_TOT_TURNO", "QT_VOTOS_NOMINAIS")
  missing <- setdiff(required, names(data))
  if (length(missing))
    stop("Unrecognised TSE layout; missing columns: ",
         paste(missing, collapse = ", "), call. = FALSE)
  d <- as.data.frame(lapply(data[required], function(x) enc2utf8(as.character(x))),
                     stringsAsFactors = FALSE)
  for (col in c("NR_TURNO", "QT_VOTOS_NOMINAIS")) {
    v <- suppressWarnings(as.numeric(d[[col]]))
    if (anyNA(v) || any(v < 0)) stop("Invalid values in ", col, ".", call. = FALSE)
    d[[col]] <- v
  }
  d <- d[d$CD_CARGO %in% names(.offices), , drop = FALSE]
  office <- unname(.offices[d$CD_CARGO])
  # Statewide offices: votes are summed over every municipality and zone.
  statewide <- !office %in% .municipal_offices
  d$CD_MUNICIPIO[statewide] <- NA_character_
  d$NM_MUNICIPIO[statewide] <- NA_character_
  keys <- setdiff(required, "QT_VOTOS_NOMINAIS")
  d <- dplyr::summarise(
    dplyr::group_by(d, dplyr::across(dplyr::all_of(keys))),
    votes = sum(.data$QT_VOTOS_NOMINAIS), .groups = "drop")
  d <- dplyr::group_by(d, .data$ANO_ELEICAO, .data$CD_ELEICAO, .data$SG_UF,
                       .data$CD_MUNICIPIO, .data$SQ_CANDIDATO)
  d <- dplyr::ungroup(dplyr::filter(d, .data$NR_TURNO == max(.data$NR_TURNO)))
  status <- normalize_text(d$DS_SIT_TOT_TURNO)
  allowed <- c("ELEITO", "ELEITO POR QP", "ELEITO POR MEDIA")
  if (include_alternates) allowed <- c(allowed, "SUPLENTE")
  d <- d[status %in% allowed, , drop = FALSE]
  out <- tibble::tibble(
    year = as.integer(d$ANO_ELEICAO), election_id = d$CD_ELEICAO,
    round = as.integer(d$NR_TURNO), state = d$SG_UF,
    municipality_tse_id = d$CD_MUNICIPIO, municipality = d$NM_MUNICIPIO,
    office = unname(.offices[d$CD_CARGO]), candidate_id = d$SQ_CANDIDATO,
    name = d$NM_CANDIDATO, ballot_name = d$NM_URNA_CANDIDATO,
    party_at_election = d$SG_PARTIDO, election_status = d$DS_SIT_TOT_TURNO,
    votes = as.numeric(d$votes), reference = "election_result")
  out[order(out$state, out$municipality, out$office, out$name), , drop = FALSE]
}

#' @rdname normalize_elected
#' @param dados,incluir_suplentes Portuguese aliases of `data` and
#'   `include_alternates`.
#' @export
normalizar_eleitos <- function(dados, incluir_suplentes = FALSE) {
  normalize_elected(dados, incluir_suplentes)
}
