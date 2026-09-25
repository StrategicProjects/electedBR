# Columns of the curated office-holding events table.
.event_columns <- c("year", "candidate_id", "name", "office", "state", "municipality_tse_id",
                    "event", "date", "successor_candidate_id", "successor_name",
                    "successor_date", "source", "notes")
.event_types <- c("resignation", "death", "removal", "leave", "return")

.parse_events <- function(x) {
  missing <- setdiff(.event_columns, names(x))
  if (length(missing))
    stop("Invalid events table; missing columns: ", paste(missing, collapse = ", "),
         call. = FALSE)
  x <- x[.event_columns]
  for (col in setdiff(.event_columns, c("year", "date", "successor_date")))
    x[[col]] <- enc2utf8(as.character(x[[col]]))
  x$year <- as.integer(x$year)
  x$date <- as.Date(x$date)
  x$successor_date <- as.Date(x$successor_date)
  x[x == ""] <- NA
  bad <- setdiff(unique(x$event), .event_types)
  if (length(bad) || anyNA(x$year) || anyNA(x$date) || anyNA(x$candidate_id))
    stop("Invalid events table: unknown event type or missing year/date/candidate_id.",
         call. = FALSE)
  tibble::as_tibble(x[order(x$date), , drop = FALSE])
}

#' Office-holding events for elected officials
#'
#' A curated table of changes in office holding after the election (an
#' official who resigned, died, was removed or took leave, and who succeeded
#' them), for the offices covered by [get_elected()] that have no official
#' API of sitting members: mayors, governors and their deputies. It is
#' maintained in the package repository, served from the same host as the
#' yearly files and refreshed on demand, not on a schedule; an official absent
#' from the table has simply not been recorded, which is not evidence of
#' being in office. Every row cites its source. Contributions are welcome at
#' <https://github.com/StrategicProjects/electedBR>.
#'
#' @param events Optional data frame with the same columns, used instead of
#'   downloading (for example a local copy under review).
#' @inheritParams get_deputies
#' @inheritParams get_elected
#' @return A tibble with the columns `year` and `candidate_id` (identifying
#'   the official in the yearly file of that election), `name`, `office`,
#'   `state`, `municipality_tse_id`, `event` (`resignation`, `death`,
#'   `removal`, `leave` or `return`), `date`, `successor_candidate_id`,
#'   `successor_name`, `successor_date` (when the successor took office),
#'   `source` (URL of an official or press record) and `notes`, plus
#'   `retrieved_at`.
#' @seealso [get_elected()], whose `as_of` argument applies these events.
#' @examplesIf interactive()
#' get_officeholding_events(cache_dir = tempdir())
#' @export
get_officeholding_events <- function(events = NULL, refresh = FALSE, max_age_hours = 24,
                                     cache_dir = elected_cache_dir(),
                                     base_url = getOption("electedBR.base_url")) {
  if (!is.null(events)) return(.parse_events(as.data.frame(events)))
  url <- paste0(sub("/+$", "", base_url %||% .data_base_url), "/officeholding_events.csv")
  .cached_table("officeholding_events_v1", function() {
    tmp <- tempfile(fileext = ".csv")
    on.exit(unlink(tmp), add = TRUE)
    req <- httr2::request(url)
    req <- httr2::req_user_agent(req, "electedBR (https://github.com/StrategicProjects/electedBR)")
    req <- httr2::req_retry(req, max_tries = 3, is_transient = .is_transient)
    req <- httr2::req_timeout(req, 120)
    httr2::req_perform(req, path = tmp)
    .parse_events(utils::read.csv(tmp, colClasses = "character", encoding = "UTF-8",
                                  na.strings = c("", "NA")))
  }, refresh, cache_dir, max_age_hours)
}

#' @rdname get_officeholding_events
#' @param eventos,atualizar,validade_horas Portuguese aliases of `events`,
#'   `refresh` and `max_age_hours`.
#' @export
consultar_eventos_exercicio <- function(eventos = NULL, atualizar = FALSE, validade_horas = 24,
                                        cache_dir = elected_cache_dir(),
                                        base_url = getOption("electedBR.base_url")) {
  get_officeholding_events(eventos, atualizar, validade_horas, cache_dir, base_url)
}

`%||%` <- function(x, y) if (is.null(x)) y else x

# Adds status_as_of / status_date / office_as_of / status_source to an
# elected table, from the events dated on or before `as_of`. The latest event
# per official wins; a successor inherits the office of the official who left.
.apply_events <- function(x, events, as_of) {
  ev <- events[events$year %in% unique(x$year) & events$date <= as_of, , drop = FALSE]
  ev <- ev[order(ev$date), , drop = FALSE]
  x$status_as_of <- rep("no_change_recorded", nrow(x))
  x$status_date <- as.Date(rep(NA_character_, nrow(x)))
  x$office_as_of <- x$office
  x$status_source <- rep(NA_character_, nrow(x))
  if (!nrow(ev)) return(x)
  last <- ev[!duplicated(ev$candidate_id, fromLast = TRUE), , drop = FALSE]
  i <- match(x$candidate_id, last$candidate_id)
  hit <- !is.na(i)
  x$status_as_of[hit] <- last$event[i[hit]]
  x$status_date[hit] <- last$date[i[hit]]
  x$status_source[hit] <- last$source[i[hit]]
  succ <- ev[!is.na(ev$successor_candidate_id) & !is.na(ev$successor_date) &
               ev$successor_date <= as_of & ev$event != "return", , drop = FALSE]
  succ <- succ[!duplicated(succ$successor_candidate_id, fromLast = TRUE), , drop = FALSE]
  j <- match(x$candidate_id, succ$successor_candidate_id)
  hit <- !is.na(j) & x$status_as_of == "no_change_recorded"
  x$status_as_of[hit] <- "succession"
  x$status_date[hit] <- succ$successor_date[j[hit]]
  x$office_as_of[hit] <- succ$office[j[hit]]
  x$status_source[hit] <- succ$source[j[hit]]
  x
}
