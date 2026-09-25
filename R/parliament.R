# ---- JSON helpers for the Chamber and Senate open data APIs -----------------

.scalar <- function(x) {
  if (is.null(x) || !length(x)) return(NA_character_)
  if (length(x) != 1L || is.list(x)) stop("Unexpected scalar in official API.", call. = FALSE)
  as.character(x)
}

# The Senate API encodes a single record as an object and several as an
# array; `key` is a field present in every record.
.records <- function(x, key) {
  if (is.null(x)) return(list())
  if (!is.list(x)) stop("Unexpected records in official API.", call. = FALSE)
  if (key %in% names(x)) list(x) else x
}

.role <- function(x) {
  y <- normalize_text(x)
  ifelse(is.na(y), "unknown", ifelse(grepl("SUPLENTE", y), "alternate",
    ifelse(y == "TITULAR", "principal", "unknown")))
}

.status <- function(x) {
  y <- normalize_text(x)
  ifelse(is.na(y), "unknown", ifelse(y == "EXERCICIO", "serving",
    ifelse(grepl("LICEN", y), "on_leave",
      ifelse(grepl("FIM_MANDATO|FALEC|RENUNC|CASS", y), "ended", "other"))))
}

# Gateway errors (502/504) are as transient as 503 for these APIs.
.is_transient <- function(resp) httr2::resp_status(resp) %in% c(429, 500, 502, 503, 504)

.json_get <- function(url) {
  # Only official hosts; also applies to pagination links returned by the API.
  if (!grepl("^https://(dadosabertos[.]camara[.]leg[.]br|legis[.]senado[.]leg[.]br)/", url))
    stop("Untrusted API URL: ", url, call. = FALSE)
  req <- httr2::request(url)
  req <- httr2::req_headers(req, Accept = "application/json")
  req <- httr2::req_user_agent(req, "electedBR (https://github.com/StrategicProjects/electedBR)")
  req <- httr2::req_timeout(req, 60)
  req <- httr2::req_retry(req, max_tries = 3, is_transient = .is_transient)
  httr2::resp_body_json(httr2::req_perform(req), simplifyVector = FALSE)
}

.camara_pages <- function(url, fetch = .json_get) {
  rows <- list()
  visited <- character()
  repeat {
    if (url %in% visited) stop("Pagination loop detected.", call. = FALSE)
    visited <- c(visited, url)
    j <- fetch(url)
    if (is.null(j$dados) || !is.list(j$dados)) stop("Invalid Chamber schema.", call. = FALSE)
    rows <- c(rows, j$dados)
    nexts <- Filter(function(x) identical(x$rel, "next"), j$links)
    if (!length(nexts)) break
    if (length(nexts) != 1L) stop("Ambiguous pagination.", call. = FALSE)
    url <- .scalar(nexts[[1]]$href)
  }
  rows
}

# ---- current composition ---------------------------------------------------

.empty_current <- function() {
  tibble::tibble(person_id = character(), source_id = character(), name = character(),
    state = character(), office = character(), current_party = character(),
    mandate_id = character(), mandate_role = character(), mandate_role_raw = character(),
    exercise_status = character(), exercise_status_raw = character(),
    exercise_start = as.Date(character()), exercise_end = as.Date(character()),
    status_recorded_at = character(), source_updated_at = character(),
    source = character(), reference = character())
}

.parse_deputy <- function(j) {
  d <- j$dados
  s <- d$ultimoStatus
  if (is.null(s) || is.na(.scalar(d$id)) || is.na(.scalar(s$nome)))
    stop("Invalid Chamber deputy detail schema.", call. = FALSE)
  tibble::tibble(person_id = paste0("camara:", d$id), source_id = .scalar(d$id),
    name = .scalar(s$nome), state = .scalar(s$siglaUf), office = "federal_deputy",
    current_party = .scalar(s$siglaPartido), mandate_id = NA_character_,
    mandate_role = .role(.scalar(s$condicaoEleitoral)),
    mandate_role_raw = .scalar(s$condicaoEleitoral),
    exercise_status = .status(.scalar(s$situacao)), exercise_status_raw = .scalar(s$situacao),
    # ultimoStatus$data may reflect a party or name change; it is not a start of service.
    exercise_start = as.Date(NA_character_), exercise_end = as.Date(NA_character_),
    status_recorded_at = .scalar(s$data), source_updated_at = NA_character_,
    source = paste0("https://dadosabertos.camara.leg.br/api/v2/deputados/", d$id),
    reference = "current_officeholding")
}

.senate_payload <- function(j) {
  r <- j$ListaParlamentarEmExercicio
  if (is.null(r$Parlamentares$Parlamentar))
    stop("Invalid Senate current-list schema.", call. = FALSE)
  .records(r$Parlamentares$Parlamentar, "IdentificacaoParlamentar")
}

.parse_senators <- function(j) {
  records <- .senate_payload(j)
  if (!length(records)) stop("Empty Senate list; cache not updated.", call. = FALSE)
  out <- lapply(records, function(p) {
    i <- p$IdentificacaoParlamentar
    m <- p$Mandato
    id <- .scalar(i$CodigoParlamentar)
    if (is.na(id) || is.na(.scalar(i$NomeParlamentar)))
      stop("Invalid senator identity.", call. = FALSE)
    ex <- .records(m$Exercicios$Exercicio, "CodigoExercicio")
    active <- Filter(function(x) is.na(.scalar(x$DataFim)), ex)
    # Do not guess between several open periods.
    start <- if (length(active) == 1L) .scalar(active[[1]]$DataInicio) else NA_character_
    tibble::tibble(person_id = paste0("senado:", id), source_id = id,
      name = .scalar(i$NomeParlamentar), state = .scalar(i$UfParlamentar),
      office = "senator", current_party = .scalar(i$SiglaPartidoParlamentar),
      mandate_id = .scalar(m$CodigoMandato),
      mandate_role = .role(.scalar(m$DescricaoParticipacao)),
      mandate_role_raw = .scalar(m$DescricaoParticipacao), exercise_status = "serving",
      exercise_status_raw = "ListaParlamentarEmExercicio",
      exercise_start = as.Date(start), exercise_end = as.Date(NA_character_),
      status_recorded_at = NA_character_,
      source_updated_at = .scalar(j$ListaParlamentarEmExercicio$Metadados$Versao),
      source = "https://legis.senado.leg.br/dadosabertos/senador/lista/atual.json",
      reference = "current_officeholding")
  })
  x <- dplyr::bind_rows(.empty_current(), dplyr::bind_rows(out))
  if (anyDuplicated(x$person_id)) stop("Duplicate senator in current list.", call. = FALSE)
  x
}

.filter_current <- function(x, state, party, role, status) {
  state <- .check_states(state)
  if (!is.null(state)) x <- x[x$state %in% state, , drop = FALSE]
  party <- .check_values(party, "party")
  if (!is.null(party))
    x <- x[normalize_text(x$current_party) %in% normalize_text(party), , drop = FALSE]
  if (!is.null(role)) {
    if (!length(role) || anyNA(role) || any(!role %in% c("principal", "alternate", "unknown")))
      stop("`role` must be NULL or one of \"principal\", \"alternate\", \"unknown\".",
           call. = FALSE)
    x <- x[x$mandate_role %in% role, , drop = FALSE]
  }
  if (!identical(status, "serving"))
    stop("Only `status = \"serving\"` is supported: the official lists cover ",
         "members currently in service.", call. = FALSE)
  tibble::as_tibble(x[x$exercise_status == "serving", , drop = FALSE])
}

#' Federal deputies and senators currently serving
#'
#' Retrieves the members of the Chamber of Deputies and of the Federal Senate
#' currently in service, from the open data APIs of each house. The lists
#' include alternates who are serving; `mandate_role` tells principals and
#' alternates apart, independently of the service status. Election results are
#' a different question, answered by [get_elected()].
#'
#' The Chamber list is paginated and the electoral condition of each deputy
#' comes from a detail request per deputy, so the first call without `state`
#' issues several hundred requests; results are cached for `max_age_hours`
#' hours in `cache_dir`, and every completed collection is also kept as an
#' immutable snapshot under `cache_dir/snapshots/`. A network or schema failure
#' raises an error rather than silently returning expired data.
#'
#' @param state Two-letter state abbreviations; `NULL` keeps every state.
#' @param party Party abbreviations (current affiliation).
#' @param status Only `"serving"` is supported.
#' @param role `NULL`, or one or more of `"principal"`, `"alternate"` and
#'   `"unknown"`.
#' @param refresh Logical. Collect again even if a fresh cache exists.
#' @param max_age_hours Maximum age of the cache, in hours (default six).
#' @param cache_dir Cache directory; defaults to
#'   `tools::R_user_dir("electedBR", "cache")`.
#' @return A tibble with the columns `person_id`, `source_id`, `name`, `state`,
#'   `office`, `current_party`, `mandate_id`, `mandate_role`,
#'   `mandate_role_raw`, `exercise_status`, `exercise_status_raw`,
#'   `exercise_start`, `exercise_end`, `status_recorded_at`,
#'   `source_updated_at`, `source`, `reference` and `retrieved_at`. Columns
#'   ending in `_raw` keep the label used by the source; `person_id` is
#'   namespaced (`camara:204379`, `senado:5322`) and is not a TSE identifier.
#' @seealso [get_service_history()] for the status records and service
#'   periods of one member.
#' @examplesIf interactive()
#' get_senators(state = "PE", cache_dir = tempdir())
#' get_deputies(state = c("PE", "PB"), role = "alternate", cache_dir = tempdir())
#' consultar_senadores(uf = "PE", cache_dir = tempdir())
#' @export
get_deputies <- function(state = NULL, party = NULL, status = "serving", role = NULL,
                         refresh = FALSE, max_age_hours = 6,
                         cache_dir = tools::R_user_dir("electedBR", "cache")) {
  .filter_current(.empty_current(), state, party, role, status)
  scope <- if (is.null(state)) "ALL" else paste(sort(unique(normalize_text(state))), collapse = "-")
  x <- .cached_table(paste0("camara_current_v1_", scope), function() {
    url <- "https://dadosabertos.camara.leg.br/api/v2/deputados?itens=100&ordenarPor=id"
    if (!is.null(state)) url <- paste0(url, "&siglaUf=",
      utils::URLencode(paste(unique(normalize_text(state)), collapse = ","), reserved = TRUE))
    rows <- .camara_pages(url)
    ids <- vapply(rows, function(x) .scalar(x$id), character(1))
    if (!length(ids) || anyNA(ids) || anyDuplicated(ids))
      stop("Invalid deputy list.", call. = FALSE)
    details <- lapply(ids, function(id) {
      .parse_deputy(.json_get(paste0("https://dadosabertos.camara.leg.br/api/v2/deputados/", id)))
    })
    dplyr::bind_rows(details)
  }, refresh, cache_dir, max_age_hours)
  .filter_current(x, state, party, role, status)
}

#' @rdname get_deputies
#' @export
get_senators <- function(state = NULL, party = NULL, status = "serving", role = NULL,
                         refresh = FALSE, max_age_hours = 6,
                         cache_dir = tools::R_user_dir("electedBR", "cache")) {
  .filter_current(.empty_current(), state, party, role, status)
  x <- .cached_table("senado_current_v1", function() {
    .parse_senators(.json_get("https://legis.senado.leg.br/dadosabertos/senador/lista/atual.json"))
  }, refresh, cache_dir, max_age_hours)
  .filter_current(x, state, party, role, status)
}

.pt_role <- function(x) {
  if (is.null(x)) return(NULL)
  map <- c(titular = "principal", suplente = "alternate", desconhecido = "unknown")
  if (anyNA(x) || any(!x %in% names(map)))
    stop("`condicao` must be NULL or one of \"titular\", \"suplente\", \"desconhecido\".",
         call. = FALSE)
  unname(map[x])
}

.pt_status <- function(situacao) {
  if (!identical(situacao, "em_exercicio"))
    stop("Only `situacao = \"em_exercicio\"` is supported.", call. = FALSE)
  "serving"
}

#' @rdname get_deputies
#' @param uf,partido,situacao,condicao,atualizar,validade_horas Portuguese
#'   aliases of `state`, `party`, `status` (`"em_exercicio"`), `role`
#'   (`"titular"`, `"suplente"`, `"desconhecido"`), `refresh` and
#'   `max_age_hours`.
#' @export
consultar_deputados <- function(uf = NULL, partido = NULL, situacao = "em_exercicio",
                                condicao = NULL, atualizar = FALSE, validade_horas = 6,
                                cache_dir = tools::R_user_dir("electedBR", "cache")) {
  get_deputies(uf, partido, .pt_status(situacao), .pt_role(condicao), atualizar,
               validade_horas, cache_dir)
}

#' @rdname get_deputies
#' @export
consultar_senadores <- function(uf = NULL, partido = NULL, situacao = "em_exercicio",
                                condicao = NULL, atualizar = FALSE, validade_horas = 6,
                                cache_dir = tools::R_user_dir("electedBR", "cache")) {
  get_senators(uf, partido, .pt_status(situacao), .pt_role(condicao), atualizar,
               validade_horas, cache_dir)
}
