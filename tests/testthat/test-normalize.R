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

test_that("presidential and gubernatorial rows are dropped", {
  x <- tse_fixture()
  x$CD_CARGO <- c("1", "3", "13", "13", "13")
  expect_equal(nrow(normalize_elected(x)), 2)
})

test_that("normalize_text strips accents and case", {
  expect_identical(normalize_text(c(" São João ", "Exercício", NA)),
                   c("SAO JOAO", "EXERCICIO", NA))
})
