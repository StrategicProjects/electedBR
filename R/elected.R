#' Candidates elected in Brazilian elections
#'
#' Returns the candidates elected (and optionally the alternates) in a
#' Brazilian election year, from the yearly files derived from the TSE open
#' data and hosted by the package (see [elected_years]). Municipal offices
#' (mayor, deputy mayor, councilor) are available for municipal election years
#' (2020, 2024, ...) and legislative offices (senator, federal, state and
#' district deputy) for general election years (2018, 2022, ...).
#'
#' The first call for a year downloads its Parquet file (a few megabytes) into
#' `cache_dir`; later calls read the local copy. Results describe who was
#' elected in the poll: they do not establish who currently holds office nor
#' current party membership. For sitting members of Congress use
#' [get_deputies()] and [get_senators()].
#'
#' @param year Election year; one of `elected_years$year`.
#' @param state One or more two-letter state abbreviations (`"PE"`, `"SP"`).
#'   `NULL` (the default) keeps every state.
#' @param municipality Municipality names (matched exactly, ignoring accents
#'   and case) or TSE municipality codes (not IBGE codes). Municipal offices
#'   only.
#' @param office One or more of `"mayor"`, `"deputy_mayor"`, `"councilor"`,
#'   `"senator"`, `"federal_deputy"`, `"state_deputy"` and
#'   `"district_deputy"`. `NULL` keeps every office in the year.
#' @param party Party abbreviations at the time of the election.
#' @param include_alternates Logical. Also return the candidates classified as
#'   `SUPLENTE` (alternate) in the TSE file. This is the classification at the
#'   poll, not a current substitution queue.
#' @param cache_dir Directory where the yearly files are stored. Defaults to
#'   the per-user cache directory returned by [tools::R_user_dir()].
#' @param refresh Logical. Download the file again even if a copy is cached.
#' @param base_url Optional base URL of a mirror hosting the files listed in
#'   [elected_years]. Defaults to `getOption("electedBR.base_url")`; when
#'   `NULL`, the `url` column of [elected_years] is used.
#' @return A tibble with the columns documented in [normalize_elected()]:
#'   `year`, `election_id`, `round`, `state`, `municipality_tse_id`,
#'   `municipality`, `office`, `candidate_id`, `name`, `ballot_name`,
#'   `party_at_election`, `election_status`, `votes` and `reference`. An empty
#'   tibble with the same columns is returned when no row matches. The
#'   attributes `source` (TSE dataset page) and `notice` are set.
#' @seealso [get_mayors()], [get_councilors()], [elected_years],
#'   [elected_clear_cache()].
#' @examplesIf interactive()
#' # Mayors elected in Pernambuco in 2024
#' get_mayors(state = "PE", municipality = c("Recife", "Caruaru"),
#'            cache_dir = tempdir())
#'
#' # Federal deputies elected in 2022, including alternates
#' get_elected(2022, state = "PE", office = "federal_deputy",
#'             include_alternates = TRUE, cache_dir = tempdir())
#'
#' # Same query through the Portuguese alias
#' consultar_eleitos(2022, uf = "PE", cargo = "DEPUTADO FEDERAL",
#'                   cache_dir = tempdir())
#' @export
get_elected <- function(year = 2024L, state = NULL, municipality = NULL,
                        office = NULL, party = NULL, include_alternates = FALSE,
                        cache_dir = tools::R_user_dir("electedBR", "cache"),
                        refresh = FALSE,
                        base_url = getOption("electedBR.base_url")) {
  index <- .elected_index()
  year <- .check_year(year, index$year)
  office <- .check_office(office, year)
  .check_flag(include_alternates, "include_alternates")
  .check_flag(refresh, "refresh")
  municipality <- .check_values(municipality, "municipality")
  party <- .check_values(party, "party")
  if (!is.null(municipality) && any(!office %in% .municipal_offices))
    stop("`municipality` applies to municipal offices only; statewide offices ",
         "represent the whole state, filter them with `state`.", call. = FALSE)
  general <- .is_general(year)
  state <- .check_states(state, if (general) .states_df else .states)
  path <- .elected_file(index[index$year == year, , drop = FALSE], cache_dir,
                        refresh, base_url)
  x <- tibble::as_tibble(nanoparquet::read_parquet(path))
  x <- x[x$office %in% office, , drop = FALSE]
  if (!is.null(state)) x <- x[x$state %in% state, , drop = FALSE]
  if (!is.null(municipality)) {
    keep <- normalize_text(x$municipality) %in% normalize_text(municipality) |
      x$municipality_tse_id %in% as.character(municipality)
    x <- x[keep, , drop = FALSE]
  }
  if (!is.null(party))
    x <- x[normalize_text(x$party_at_election) %in% normalize_text(party), , drop = FALSE]
  if (!include_alternates)
    x <- x[normalize_text(x$election_status) != "SUPLENTE", , drop = FALSE]
  attr(x, "source") <- sprintf("https://dadosabertos.tse.jus.br/dataset/resultados-%d", year)
  attr(x, "notice") <- paste("Election results; they do not establish current",
                             "office holding or party membership.")
  x
}

#' @rdname get_elected
#' @export
get_mayors <- function(year = 2024L, state = NULL, municipality = NULL,
                       party = NULL,
                       cache_dir = tools::R_user_dir("electedBR", "cache"),
                       refresh = FALSE,
                       base_url = getOption("electedBR.base_url")) {
  get_elected(year, state, municipality, "mayor", party, FALSE, cache_dir,
              refresh, base_url)
}

#' @rdname get_elected
#' @export
get_councilors <- function(year = 2024L, state = NULL, municipality = NULL,
                           party = NULL, include_alternates = FALSE,
                           cache_dir = tools::R_user_dir("electedBR", "cache"),
                           refresh = FALSE,
                           base_url = getOption("electedBR.base_url")) {
  get_elected(year, state, municipality, "councilor", party,
              include_alternates, cache_dir, refresh, base_url)
}

#' @rdname get_elected
#' @param ano,uf,municipio,cargo,partido,incluir_suplentes,atualizar Portuguese
#'   aliases of `year`, `state`, `municipality`, `office`, `party`,
#'   `include_alternates` and `refresh`. `cargo` also accepts the Portuguese
#'   labels `"PREFEITO"`, `"VICE-PREFEITO"`, `"VEREADOR"`, `"SENADOR"`,
#'   `"DEPUTADO FEDERAL"`, `"DEPUTADO ESTADUAL"` and `"DEPUTADO DISTRITAL"`.
#' @export
consultar_eleitos <- function(ano = 2024L, uf = NULL, municipio = NULL,
                              cargo = NULL, partido = NULL,
                              incluir_suplentes = FALSE,
                              cache_dir = tools::R_user_dir("electedBR", "cache"),
                              atualizar = FALSE,
                              base_url = getOption("electedBR.base_url")) {
  get_elected(ano, uf, municipio, .office_from_pt(cargo), partido,
              incluir_suplentes, cache_dir, atualizar, base_url)
}

#' @rdname get_elected
#' @export
consultar_prefeitos <- function(ano = 2024L, uf = NULL, municipio = NULL,
                                partido = NULL,
                                cache_dir = tools::R_user_dir("electedBR", "cache"),
                                atualizar = FALSE,
                                base_url = getOption("electedBR.base_url")) {
  get_mayors(ano, uf, municipio, partido, cache_dir, atualizar, base_url)
}

#' @rdname get_elected
#' @export
consultar_vereadores <- function(ano = 2024L, uf = NULL, municipio = NULL,
                                 partido = NULL, incluir_suplentes = FALSE,
                                 cache_dir = tools::R_user_dir("electedBR", "cache"),
                                 atualizar = FALSE,
                                 base_url = getOption("electedBR.base_url")) {
  get_councilors(ano, uf, municipio, partido, incluir_suplentes, cache_dir,
                 atualizar, base_url)
}

# ---- helpers ---------------------------------------------------------------

.is_general <- function(year) year %% 4L == 2L

.check_year <- function(year, available) {
  if (length(year) != 1L || is.na(year) || !is.numeric(year) ||
      !as.integer(year) %in% available)
    stop("`year` must be one of: ", paste(available, collapse = ", "),
         " (see `elected_years`).", call. = FALSE)
  as.integer(year)
}

.check_office <- function(office, year) {
  valid <- if (.is_general(year)) .general_offices else .municipal_offices
  if (is.null(office)) return(valid)
  office <- tolower(trimws(as.character(office)))
  bad <- setdiff(office, unname(.offices))
  if (!length(office) || anyNA(office) || length(bad))
    stop("Invalid `office`: ", paste(bad, collapse = ", "), ". Use one of ",
         paste(unname(.offices), collapse = ", "), ".", call. = FALSE)
  wrong <- setdiff(office, valid)
  if (length(wrong))
    stop("Office and year do not match: ", paste(wrong, collapse = ", "),
         if (.is_general(year)) " is a municipal office, elected in 2020, 2024, ..."
         else " is elected in general elections (2018, 2022, ...).", call. = FALSE)
  office
}

# Portuguese labels (or English names) -> English office names.
.office_from_pt <- function(cargo) {
  if (is.null(cargo)) return(NULL)
  key <- normalize_text(cargo)
  out <- ifelse(key %in% names(.office_pt), unname(.office_pt[key]), tolower(trimws(cargo)))
  bad <- setdiff(out, unname(.offices))
  if (!length(out) || anyNA(out) || length(bad))
    stop("Invalid `cargo`: ", paste(cargo[out %in% bad], collapse = ", "),
         ". Use one of ", paste(names(.office_pt), collapse = ", "), ".", call. = FALSE)
  out
}

.elected_index <- function() {
  env <- new.env(parent = emptyenv())
  utils::data("elected_years", package = "electedBR", envir = env)
  env$elected_years
}

# Returns the local path of the yearly file, downloading it when needed. A
# download goes to a temporary file first, so an interrupted transfer is never
# mistaken for a complete file, and is checked against the size and MD5
# recorded in `elected_years`.
.elected_file <- function(row, cache_dir, refresh = FALSE, base_url = NULL) {
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  path <- file.path(cache_dir, row$file)
  if (file.exists(path) && !refresh) return(path)
  url <- if (is.null(base_url)) row$url else paste0(sub("/+$", "", base_url), "/", row$file)
  message("Downloading ", row$file, " from ", url)
  tmp <- tempfile(tmpdir = cache_dir, fileext = ".part")
  on.exit(unlink(tmp), add = TRUE)
  req <- httr2::request(url)
  req <- httr2::req_user_agent(req, "electedBR (https://github.com/StrategicProjects/electedBR)")
  req <- httr2::req_retry(req, max_tries = 3, is_transient = .is_transient)
  req <- httr2::req_timeout(req, 600)
  httr2::req_perform(req, path = tmp)
  if (!is.na(row$bytes) && file.size(tmp) != row$bytes)
    stop("Downloaded ", row$file, " has an unexpected size; the file was discarded.",
         call. = FALSE)
  if (!is.na(row$md5) && unname(tools::md5sum(tmp)) != row$md5)
    stop("Downloaded ", row$file, " failed the MD5 check; the file was discarded.",
         call. = FALSE)
  if (!file.copy(tmp, path, overwrite = TRUE))
    stop("Could not write to ", cache_dir, ".", call. = FALSE)
  path
}
