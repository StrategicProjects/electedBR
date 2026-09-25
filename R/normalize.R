#' Consolidate TSE files into the candidates elected
#'
#' Turns the raw *votação nominal por município e zona* table published by the
#' Superior Electoral Court (TSE) into one row per elected candidate. Votes are
#' summed over electoral zones (over municipalities for statewide offices and
#' over the whole country for president), the last round available for each
#' candidate is kept, and distinct elections held on the same date (for
#' instance ordinary and supplementary polls, which have different
#' `CD_ELEICAO` codes) are never merged.
#'
#' Running mates (vice president, vice governors and vice mayors) receive no
#' votes of their own and are absent from the vote files. When the TSE
#' *candidatos* table of the same year is given in `candidates`, the running
#' mates classified as elected are added with `votes = NA` and
#' `ticket_candidate_id` pointing to the head of their ticket (same
#' `NR_CANDIDATO` in the same election and electoral unit).
#'
#' This is the function that builds the yearly files distributed with the
#' package; it is exported so that the same rules can be applied to a fresh
#' TSE download (for example the output of `electionsBR::elections_tse()`).
#'
#' @param data A data frame with the TSE vote-by-municipality-and-zone layout.
#'   The columns `ANO_ELEICAO`, `CD_ELEICAO`, `NR_TURNO`, `SG_UF`,
#'   `CD_MUNICIPIO`, `NM_MUNICIPIO`, `CD_CARGO`, `DS_CARGO`, `SQ_CANDIDATO`,
#'   `NM_CANDIDATO`, `NM_URNA_CANDIDATO`, `SG_PARTIDO`, `DS_SIT_TOT_TURNO` and
#'   `QT_VOTOS_NOMINAIS` are required (case-insensitive).
#' @param candidates Optional data frame with the TSE candidates layout
#'   (`consulta_cand`), used to add the elected running mates. The columns
#'   `ANO_ELEICAO`, `CD_ELEICAO`, `NR_TURNO`, `SG_UF`, `SG_UE`, `NM_UE`,
#'   `CD_CARGO`, `SQ_CANDIDATO`, `NR_CANDIDATO`, `NM_CANDIDATO`,
#'   `NM_URNA_CANDIDATO`, `SG_PARTIDO` and `DS_SIT_TOT_TURNO` are required.
#' @param include_alternates Logical. Also keep candidates whose final status
#'   is `SUPLENTE` (alternate) in the TSE file. Senate ticket alternates have no
#'   votes of their own and are not covered; see [get_senators()] for the
#'   alternates currently serving.
#' @return A tibble with one row per candidate and election, with the columns
#'   `year`, `election_id`, `round`, `state`, `municipality_tse_id`,
#'   `municipality`, `office`, `candidate_id`, `ticket_candidate_id`, `name`,
#'   `ballot_name`, `party_at_election`, `election_status`, `votes` and
#'   `reference`. `office` is one of `president`, `vice_president`,
#'   `governor`, `vice_governor`, `senator`, `federal_deputy`, `state_deputy`,
#'   `district_deputy`, `mayor`, `vice_mayor` or `councilor`. For statewide
#'   offices `municipality_tse_id` and `municipality` are `NA`; for president
#'   and vice president `state` is `NA` as well. `ticket_candidate_id` is `NA`
#'   except for running mates, and `votes` is `NA` for running mates.
#' @seealso [get_elected()] for the ready-made yearly files.
#' @examples
#' votes <- data.frame(
#'   ANO_ELEICAO = 2024, CD_ELEICAO = "619", NR_TURNO = 1, SG_UF = "PE",
#'   CD_MUNICIPIO = "25313", NM_MUNICIPIO = "RECIFE", CD_CARGO = "13",
#'   DS_CARGO = "Vereador", SQ_CANDIDATO = c("1", "1", "2"),
#'   NM_CANDIDATO = c("ANA", "ANA", "BRUNO"),
#'   NM_URNA_CANDIDATO = c("ANA", "ANA", "BRUNO"),
#'   SG_PARTIDO = c("PSB", "PSB", "PT"),
#'   DS_SIT_TOT_TURNO = c("ELEITO POR QP", "ELEITO POR QP", "SUPLENTE"),
#'   QT_VOTOS_NOMINAIS = c(100, 50, 200)
#' )
#' normalize_elected(votes)
#' normalize_elected(votes, include_alternates = TRUE)
#' @export
normalize_elected <- function(data, candidates = NULL, include_alternates = FALSE) {
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
  # Statewide offices: votes are summed over every municipality and zone;
  # nationwide offices also over every state (including votes cast abroad).
  statewide <- !office %in% .municipal_offices
  d$CD_MUNICIPIO[statewide] <- NA_character_
  d$NM_MUNICIPIO[statewide] <- NA_character_
  d$SG_UF[office %in% .national_offices] <- NA_character_
  keys <- setdiff(required, "QT_VOTOS_NOMINAIS")
  d <- dplyr::summarise(
    dplyr::group_by(d, dplyr::across(dplyr::all_of(keys))),
    votes = sum(.data$QT_VOTOS_NOMINAIS), .groups = "drop")
  d <- .last_round(d, c("ANO_ELEICAO", "CD_ELEICAO", "SG_UF", "CD_MUNICIPIO", "SQ_CANDIDATO"))
  status <- normalize_text(d$DS_SIT_TOT_TURNO)
  allowed <- c("ELEITO", "ELEITO POR QP", "ELEITO POR MEDIA")
  if (include_alternates) allowed <- c(allowed, "SUPLENTE")
  d <- d[status %in% allowed, , drop = FALSE]
  out <- tibble::tibble(
    year = as.integer(d$ANO_ELEICAO), election_id = d$CD_ELEICAO,
    round = as.integer(d$NR_TURNO), state = d$SG_UF,
    municipality_tse_id = d$CD_MUNICIPIO, municipality = d$NM_MUNICIPIO,
    office = unname(.offices[d$CD_CARGO]), candidate_id = d$SQ_CANDIDATO,
    ticket_candidate_id = NA_character_,
    name = d$NM_CANDIDATO, ballot_name = d$NM_URNA_CANDIDATO,
    party_at_election = d$SG_PARTIDO, election_status = d$DS_SIT_TOT_TURNO,
    votes = as.numeric(d$votes), reference = "election_result")
  if (!is.null(candidates)) out <- dplyr::bind_rows(out, .running_mates(candidates))
  out[order(out$state, out$municipality, out$office, out$name), , drop = FALSE]
}

# Keeps, within each group, the rows of the last round a candidate took part in.
.last_round <- function(d, keys) {
  d <- dplyr::group_by(d, dplyr::across(dplyr::all_of(keys)))
  d <- dplyr::filter(d, .data$NR_TURNO == max(.data$NR_TURNO))
  dplyr::ungroup(d)
}

# Elected running mates from the TSE candidates file, linked to the head of
# their ticket by election, electoral unit and ballot number.
.running_mates <- function(candidates) {
  if (!is.data.frame(candidates))
    stop("`candidates` must be a data frame with the TSE candidates layout.", call. = FALSE)
  names(candidates) <- toupper(names(candidates))
  required <- c("ANO_ELEICAO", "CD_ELEICAO", "NR_TURNO", "SG_UF", "SG_UE", "NM_UE",
                "CD_CARGO", "SQ_CANDIDATO", "NR_CANDIDATO", "NM_CANDIDATO",
                "NM_URNA_CANDIDATO", "SG_PARTIDO", "DS_SIT_TOT_TURNO")
  missing <- setdiff(required, names(candidates))
  if (length(missing))
    stop("Unrecognised TSE candidates layout; missing columns: ",
         paste(missing, collapse = ", "), call. = FALSE)
  d <- as.data.frame(lapply(candidates[required], function(x) enc2utf8(as.character(x))),
                     stringsAsFactors = FALSE)
  d$NR_TURNO <- suppressWarnings(as.numeric(d$NR_TURNO))
  if (anyNA(d$NR_TURNO)) stop("Invalid values in NR_TURNO.", call. = FALSE)
  d$office <- unname(.offices[d$CD_CARGO])
  d <- d[d$office %in% c(names(.vice_offices), unname(.vice_offices)), , drop = FALSE]
  d <- .last_round(d, c("ANO_ELEICAO", "CD_ELEICAO", "SG_UE", "SQ_CANDIDATO"))
  d <- d[normalize_text(d$DS_SIT_TOT_TURNO) == "ELEITO", , drop = FALSE]
  # A replaced candidacy keeps the ballot number, so the head is identified
  # among the elected heads of the same office only.
  heads <- d[d$office %in% unname(.vice_offices), , drop = FALSE]
  head_key <- paste(heads$CD_ELEICAO, heads$SG_UE, heads$office, heads$NR_CANDIDATO)
  if (anyDuplicated(head_key))
    stop("Ambiguous ticket: several elected heads share an election, unit, office and number.",
         call. = FALSE)
  v <- d[d$office %in% names(.vice_offices), , drop = FALSE]
  v_office <- v$office
  key <- paste(v$CD_ELEICAO, v$SG_UE, unname(.vice_offices[v_office]), v$NR_CANDIDATO)
  municipal <- v_office %in% .municipal_offices
  national <- v_office %in% .national_offices
  tibble::tibble(
    year = as.integer(v$ANO_ELEICAO), election_id = v$CD_ELEICAO,
    round = as.integer(v$NR_TURNO),
    state = ifelse(national, NA_character_, v$SG_UF),
    municipality_tse_id = ifelse(municipal, v$SG_UE, NA_character_),
    municipality = ifelse(municipal, v$NM_UE, NA_character_),
    office = v_office, candidate_id = v$SQ_CANDIDATO,
    ticket_candidate_id = heads$SQ_CANDIDATO[match(key, head_key)],
    name = v$NM_CANDIDATO, ballot_name = v$NM_URNA_CANDIDATO,
    party_at_election = v$SG_PARTIDO, election_status = v$DS_SIT_TOT_TURNO,
    votes = NA_real_, reference = "election_result")
}

#' @rdname normalize_elected
#' @param dados,candidatos,incluir_suplentes Portuguese aliases of `data`,
#'   `candidates` and `include_alternates`.
#' @export
normalizar_eleitos <- function(dados, candidatos = NULL, incluir_suplentes = FALSE) {
  normalize_elected(dados, candidatos, incluir_suplentes)
}
