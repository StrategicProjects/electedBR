test_that("zones are summed and an alternate with more votes is not elected", {
  x <- normalize_elected(tse_fixture())
  expect_s3_class(x, "tbl_df")
  expect_equal(nrow(x), 3)
  expect_equal(x$votes[x$candidate_id == "1"], 150)
  expect_false("3" %in% x$candidate_id)
  expect_identical(unique(x$reference), "election_result")
  expect_setequal(x$office, c("mayor", "councilor"))
  y <- normalize_elected(tse_fixture(), include_alternates = TRUE)
  expect_equal(nrow(y), 4)
  expect_true("SUPLENTE" %in% y$election_status)
})

test_that("an incomplete layout fails explicitly", {
  expect_error(normalize_elected(data.frame(a = 1)), "missing columns")
  expect_error(normalize_elected(list(a = 1)), "data frame")
  bad <- tse_fixture()
  bad$QT_VOTOS_NOMINAIS[1] <- "x"
  expect_error(normalize_elected(bad), "QT_VOTOS_NOMINAIS")
})

test_that("the last round prevails and different elections stay apart", {
  x <- tse_fixture()[1, ]
  y <- x
  y$NR_TURNO <- 2
  y$QT_VOTOS_NOMINAIS <- 200
  z <- y
  z$CD_ELEICAO <- "620"
  z$QT_VOTOS_NOMINAIS <- 300
  out <- normalize_elected(rbind(x, y, z))
  expect_equal(sort(out$votes), c(200, 300))
  expect_equal(out$round, c(2L, 2L))
})

test_that("statewide votes aggregate across municipalities", {
  x <- tse_fixture()[c(1, 2, 4), ]
  x$CD_CARGO <- "6"
  x$DS_CARGO <- "Deputado Federal"
  x$ANO_ELEICAO <- "2022"
  x$CD_MUNICIPIO <- c("001", "002", "001")
  x$NM_MUNICIPIO <- c("A", "B", "A")
  a <- normalize_elected(x)
  expect_equal(nrow(a), 1)
  expect_equal(a$votes, 150)
  expect_true(all(is.na(a$municipality)))
  expect_identical(a$office, "federal_deputy")
  b <- normalizar_eleitos(x, incluir_suplentes = TRUE)
  expect_equal(nrow(b), 2)
})

test_that("president has no state and governor no municipality; votes sum nationwide", {
  x <- tse_fixture()
  x$CD_CARGO <- c("1", "1", "3", "3", "13")
  x$SQ_CANDIDATO <- c("1", "1", "2", "2", "4")
  x$NM_CANDIDATO <- x$NM_URNA_CANDIDATO <- c("A", "A", "B", "B", "D")
  x$SG_PARTIDO <- c("PSB", "PSB", "PT", "PT", "PSD")
  x$SG_UF <- c("PE", "SP", "PE", "PE", "PE")
  x$CD_MUNICIPIO <- c("1", "2", "1", "3", "1")
  x$DS_SIT_TOT_TURNO <- "ELEITO"
  out <- normalize_elected(x)
  p <- out[out$office == "president", ]
  expect_equal(nrow(p), 1)
  expect_true(is.na(p$state))
  expect_equal(p$votes, 150)
  g <- out[out$office == "governor", ]
  expect_equal(nrow(g), 1)
  expect_identical(g$state, "PE")
  expect_true(is.na(g$municipality))
  expect_equal(g$votes, 120)
})

test_that("running mates come from the candidates file, linked to the head of the ticket", {
  out <- normalize_elected(tse_fixture(), cand_fixture())
  expect_true("ticket_candidate_id" %in% names(out))
  v <- out[out$office == "vice_mayor", ]
  expect_equal(nrow(v), 1)
  expect_identical(v$candidate_id, "9")
  expect_identical(v$ticket_candidate_id, "1")
  expect_true(is.na(v$votes))
  expect_identical(v$municipality_tse_id, "25313")
  expect_identical(v$party_at_election, "PC do B")
  expect_true(all(is.na(out$ticket_candidate_id[out$office != "vice_mayor"])))
  # a second-round row wins over the first-round one
  cand <- cand_fixture()
  r2 <- cand[cand$SQ_CANDIDATO %in% c("1", "9"), ]
  r2$NR_TURNO <- 2
  cand$DS_SIT_TOT_TURNO[cand$SQ_CANDIDATO %in% c("1", "9")] <- "2\u00ba TURNO"
  out2 <- normalize_elected(tse_fixture(), rbind(cand, r2))
  expect_equal(out2$round[out2$office == "vice_mayor"], 2L)
  expect_error(normalize_elected(tse_fixture(), data.frame(a = 1)), "candidates layout")
  expect_identical(out, normalizar_eleitos(tse_fixture(), cand_fixture()))
})

test_that("normalize_text strips accents and case", {
  expect_identical(normalize_text(c(" São João ", "Exercício", NA)),
                   c("SAO JOAO", "EXERCICIO", NA))
})
