.empty_history <- function() {
  tibble::tibble(person_id = character(), name = character(), state = character(),
    office = character(), mandate_id = character(), mandate_role = character(),
    mandate_role_raw = character(), exercise_status = character(),
    exercise_status_raw = character(), party_at_record = character(),
    record_type = character(), record_at = character(),
    exercise_start = as.Date(character()), exercise_end = as.Date(character()),
    description = character(), source = character(), source_updated_at = character())
}

.parse_camara_history <- function(rows, id) {
  out <- lapply(rows, function(s) {
    if (is.na(.scalar(s$dataHora))) stop("Missing Chamber history timestamp.", call. = FALSE)
    tibble::tibble(person_id = paste0("camara:", id), name = .scalar(s$nome),
      state = .scalar(s$siglaUf), office = "federal_deputy", mandate_id = NA_character_,
      mandate_role = .role(.scalar(s$condicaoEleitoral)),
      mandate_role_raw = .scalar(s$condicaoEleitoral),
      exercise_status = .status(.scalar(s$situacao)), exercise_status_raw = .scalar(s$situacao),
      party_at_record = .scalar(s$siglaPartido), record_type = "status_record",
      record_at = .scalar(s$dataHora), exercise_start = as.Date(NA_character_),
      exercise_end = as.Date(NA_character_), description = .scalar(s$descricaoStatus),
      source = paste0("https://dadosabertos.camara.leg.br/api/v2/deputados/", id, "/historico"),
      source_updated_at = NA_character_)
  })
  x <- dplyr::bind_rows(.empty_history(), dplyr::bind_rows(out))
  x[order(x$record_at), , drop = FALSE]
}

.parse_senate_history <- function(j, id) {
  root <- j$MandatoParlamentar
  p <- root$Parlamentar
  if (is.null(p) || !identical(.scalar(p$Codigo), id))
    stop("Invalid Senate history identity or schema.", call. = FALSE)
  mandates <- .records(p$Mandatos$Mandato, "CodigoMandato")
  out <- list()
  for (m in mandates) {
    periods <- .records(m$Exercicios$Exercicio, "CodigoExercicio")
    for (e in periods) {
      if (is.na(.scalar(e$DataInicio))) stop("Missing Senate service start.", call. = FALSE)
      out[[length(out) + 1L]] <- tibble::tibble(person_id = paste0("senado:", id),
        name = .scalar(p$Nome), state = .scalar(m$UfParlamentar), office = "senator",
        mandate_id = .scalar(m$CodigoMandato),
        mandate_role = .role(.scalar(m$DescricaoParticipacao)),
        mandate_role_raw = .scalar(m$DescricaoParticipacao),
        # An open period is not, by itself, evidence of current service.
        exercise_status = "unknown", exercise_status_raw = NA_character_,
        party_at_record = NA_character_, record_type = "service_period",
        record_at = NA_character_,
        exercise_start = as.Date(.scalar(e$DataInicio)),
        exercise_end = as.Date(.scalar(e$DataFim)),
        description = .scalar(e$DescricaoCausaAfastamento),
        source = paste0("https://legis.senado.leg.br/dadosabertos/senador/", id, "/mandatos.json"),
        source_updated_at = .scalar(root$Metadados$Versao))
    }
  }
  x <- dplyr::bind_rows(.empty_history(), dplyr::bind_rows(out))
  x[order(x$exercise_start, x$mandate_id), , drop = FALSE]
}

#' Service history of a deputy or senator
#'
#' Returns the official records about the service of one member of Congress,
#' identified by the `person_id` returned by [get_deputies()] or
#' [get_senators()]. The two houses publish different things and the
#' difference is preserved rather than reconciled:
#'
#' * Chamber (`camara:`): `record_type = "status_record"`, one row per status
#'   record with `record_at`, the situation and the party at that moment.
#'   Registry or party changes are not turned into starts or ends of service,
#'   so `exercise_start` and `exercise_end` are `NA`.
#' * Senate (`senado:`): `record_type = "service_period"`, one row per official
#'   period of each mandate, with `exercise_start` and `exercise_end`. An open
#'   period is not by itself evidence of current service; use [get_senators()]
#'   for that.
#'
#' @param person_id A single id such as `"camara:204379"` or `"senado:5322"`.
#' @inheritParams get_deputies
#' @return A tibble with the columns `person_id`, `name`, `state`, `office`,
#'   `mandate_id`, `mandate_role`, `mandate_role_raw`, `exercise_status`,
#'   `exercise_status_raw`, `party_at_record`, `record_type`, `record_at`,
#'   `exercise_start`, `exercise_end`, `description`, `source`,
#'   `source_updated_at` and `retrieved_at`.
#' @examplesIf interactive()
#' senators <- get_senators(state = "PE", cache_dir = tempdir())
#' get_service_history(senators$person_id[[1]], cache_dir = tempdir())
#' get_service_history("camara:204379", cache_dir = tempdir())
#' @export
get_service_history <- function(person_id, refresh = FALSE, max_age_hours = 6,
                                cache_dir = tools::R_user_dir("electedBR", "cache")) {
  if (!is.character(person_id) || length(person_id) != 1L || is.na(person_id) ||
      !grepl("^(camara|senado):[0-9]+$", person_id))
    stop("`person_id` must be a single id from get_deputies() or get_senators(), ",
         "such as \"camara:204379\" or \"senado:5322\".", call. = FALSE)
  parts <- strsplit(person_id, ":", fixed = TRUE)[[1]]
  house <- parts[1]
  id <- parts[2]
  .cached_table(paste0(house, "_history_v1_", id), function() {
    if (house == "camara") {
      url <- paste0("https://dadosabertos.camara.leg.br/api/v2/deputados/", id, "/historico")
      .parse_camara_history(.camara_pages(url), id)
    } else {
      url <- paste0("https://legis.senado.leg.br/dadosabertos/senador/", id, "/mandatos.json")
      .parse_senate_history(.json_get(url), id)
    }
  }, refresh, cache_dir, max_age_hours)
}

#' @rdname get_service_history
#' @param id_pessoa,atualizar,validade_horas Portuguese aliases of `person_id`,
#'   `refresh` and `max_age_hours`.
#' @export
consultar_historico_exercicio <- function(id_pessoa, atualizar = FALSE, validade_horas = 6,
                                          cache_dir = tools::R_user_dir("electedBR", "cache")) {
  get_service_history(id_pessoa, atualizar, validade_horas, cache_dir)
}
