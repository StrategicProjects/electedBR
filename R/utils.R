# Brazilian states. The Federal District elects district deputies and
# senators in general elections but holds no municipal election.
.states <- c("AC", "AL", "AP", "AM", "BA", "CE", "ES", "GO", "MA", "MT",
             "MS", "MG", "PA", "PB", "PR", "PE", "PI", "RJ", "RN", "RS",
             "RO", "RR", "SC", "SP", "SE", "TO")
.states_df <- sort(c(.states, "DF"))

# Offices covered, keyed by the TSE `CD_CARGO` code used in both the vote
# files and the candidates file.
.offices <- c(`1` = "president", `2` = "vice_president", `3` = "governor",
              `4` = "vice_governor", `5` = "senator", `6` = "federal_deputy",
              `7` = "state_deputy", `8` = "district_deputy", `11` = "mayor",
              `12` = "vice_mayor", `13` = "councilor")
.municipal_offices <- c("mayor", "vice_mayor", "councilor")
.general_offices <- c("president", "vice_president", "governor", "vice_governor",
                      "senator", "federal_deputy", "state_deputy", "district_deputy")
# Running mates have no votes of their own: they come from the candidates
# file, linked to the head of the ticket.
.vice_offices <- c(vice_president = "president", vice_governor = "governor",
                   vice_mayor = "mayor")
# Nationwide offices carry no state.
.national_offices <- c("president", "vice_president")

# Portuguese office labels accepted by the `consultar_*()` aliases.
.office_pt <- c(PRESIDENTE = "president", `VICE-PRESIDENTE` = "vice_president",
                GOVERNADOR = "governor", `VICE-GOVERNADOR` = "vice_governor",
                PREFEITO = "mayor", `VICE-PREFEITO` = "vice_mayor",
                VEREADOR = "councilor", SENADOR = "senator",
                `DEPUTADO FEDERAL` = "federal_deputy",
                `DEPUTADO ESTADUAL` = "state_deputy",
                `DEPUTADO DISTRITAL` = "district_deputy")

# Upper-case, trimmed and stripped of Portuguese diacritics, so that names
# and labels compare regardless of accents and case. Deterministic across
# platforms (no iconv transliteration tables involved).
normalize_text <- function(x) {
  x <- enc2utf8(as.character(x))
  from <- paste0("\u00e1\u00e0\u00e2\u00e3\u00e4\u00e9\u00e8\u00ea\u00eb\u00ed\u00ec\u00ee\u00ef\u00f3\u00f2\u00f4\u00f5\u00f6\u00fa\u00f9\u00fb\u00fc\u00e7\u00f1",
                 "\u00c1\u00c0\u00c2\u00c3\u00c4\u00c9\u00c8\u00ca\u00cb\u00cd\u00cc\u00ce\u00cf\u00d3\u00d2\u00d4\u00d5\u00d6\u00da\u00d9\u00db\u00dc\u00c7\u00d1")
  to <- "aaaaaeeeeiiiiooooouuuucnAAAAAEEEEIIIIOOOOOUUUUCN"
  toupper(trimws(chartr(from, to, x)))
}

.check_flag <- function(x, name) {
  if (!is.logical(x) || length(x) != 1L || is.na(x))
    stop("`", name, "` must be TRUE or FALSE.", call. = FALSE)
  invisible(x)
}

.check_states <- function(state, allowed = .states_df) {
  if (is.null(state)) return(NULL)
  state <- unique(normalize_text(state))
  bad <- setdiff(state, allowed)
  if (!length(state) || anyNA(state) || length(bad))
    stop("Invalid state abbreviation: ", paste(bad, collapse = ", "),
         ". Use two-letter codes such as \"PE\" or \"SP\".", call. = FALSE)
  state
}

.check_values <- function(x, name) {
  if (is.null(x)) return(NULL)
  if (!length(x) || anyNA(x))
    stop("`", name, "` must not be empty or contain NA.", call. = FALSE)
  x
}
