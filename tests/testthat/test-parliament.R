test_that("deputy role is independent of service status", {
  j <- list(dados = list(id = 1, ultimoStatus = list(nome = "A", siglaUf = "PE",
    siglaPartido = "PT", condicaoEleitoral = "Suplente", situacao = "Exercício",
    data = "2026-01-01")))
  x <- electedBR:::.parse_deputy(j)
  expect_identical(x$mandate_role, "alternate")
  expect_identical(x$exercise_status, "serving")
  expect_true(is.na(x$exercise_start))
  expect_identical(x$status_recorded_at, "2026-01-01")
  expect_error(electedBR:::.parse_deputy(list(dados = list(id = 1))), "schema")
})

test_that("Senate singleton and array encodings are supported", {
  p <- list(IdentificacaoParlamentar = list(CodigoParlamentar = "1", NomeParlamentar = "A",
    UfParlamentar = "PE"), Mandato = list(DescricaoParticipacao = "1º Suplente",
    Exercicios = list(Exercicio = list(CodigoExercicio = "2", DataInicio = "2026-01-01"))))
  j <- list(ListaParlamentarEmExercicio = list(Parlamentares = list(Parlamentar = p)))
  a <- electedBR:::.parse_senators(j)
  expect_identical(a$mandate_role, "alternate")
  expect_equal(a$exercise_start, as.Date("2026-01-01"))
  p$Mandato$Exercicios$Exercicio <- list(p$Mandato$Exercicios$Exercicio)
  j$ListaParlamentarEmExercicio$Parlamentares$Parlamentar <- list(p)
  expect_identical(a, electedBR:::.parse_senators(j))
  j$ListaParlamentarEmExercicio$Parlamentares$Parlamentar <- list(p, p)
  expect_error(electedBR:::.parse_senators(j), "Duplicate")
})

test_that("pagination follows next links and detects loops", {
  calls <- 0
  fetch <- function(url) {
    calls <<- calls + 1
    if (url == "one") {
      list(dados = list(list(id = 1)), links = list(list(rel = "next", href = "two")))
    } else {
      list(dados = list(list(id = 2)), links = list())
    }
  }
  expect_length(electedBR:::.camara_pages("one", fetch), 2)
  expect_equal(calls, 2)
  bad <- function(url) list(dados = list(), links = list(list(rel = "next", href = url)))
  expect_error(electedBR:::.camara_pages("one", bad), "loop")
  expect_error(electedBR:::.json_get("https://example.com/x"), "Untrusted")
})

test_that("expired cache errors instead of returning stale data; snapshots are kept", {
  dir <- withr::local_tempdir()
  fetch <- function() tibble::tibble(value = 1)
  x <- electedBR:::.cached_table("test", fetch, FALSE, dir, 6)
  fail <- function() stop("network down")
  expect_identical(x, electedBR:::.cached_table("test", fail, FALSE, dir, 6))
  expect_error(electedBR:::.cached_table("test", fail, FALSE, dir, 0), "network down")
  expect_error(electedBR:::.cached_table("test", fail, TRUE, dir, 6), "network down")
  expect_identical(x, readRDS(file.path(dir, "test.rds"))$data)
  expect_length(list.files(file.path(dir, "snapshots", "test")), 1)
  expect_error(electedBR:::.cached_table("test", fetch, FALSE, dir, -1), "max_age_hours")
  expect_error(electedBR:::.cached_table("bad", function() 1, FALSE, dir, 6), "tibble")
})

test_that("Portuguese aliases and empty results share the schema; filters are validated", {
  dir <- withr::local_tempdir()
  x <- electedBR:::.empty_current()
  saveRDS(list(time = Sys.time(), data = x), file.path(dir, "camara_current_v1_PE.rds"))
  saveRDS(list(time = Sys.time(), data = x), file.path(dir, "senado_current_v1.rds"))
  expect_identical(get_deputies(state = "PE", cache_dir = dir),
                   consultar_deputados(uf = "PE", cache_dir = dir))
  expect_identical(get_senators(cache_dir = dir),
                   consultar_senadores(condicao = "titular", cache_dir = dir))
  expect_s3_class(get_deputies(state = "PE", cache_dir = dir), "tbl_df")
  expect_error(get_senators(status = "all", cache_dir = dir), "serving")
  expect_error(get_senators(role = "boss", cache_dir = dir), "role")
  expect_error(get_senators(state = "ZZ", cache_dir = dir), "Invalid state")
  expect_error(consultar_senadores(situacao = "todos", cache_dir = dir), "em_exercicio")
  expect_error(consultar_senadores(condicao = "chefe", cache_dir = dir), "condicao")
})

test_that("current lists are filtered by state, party and role", {
  dir <- withr::local_tempdir()
  x <- electedBR:::.empty_current()
  x <- dplyr::bind_rows(x, tibble::tibble(person_id = c("senado:1", "senado:2", "senado:3"),
    source_id = c("1", "2", "3"), name = c("A", "B", "C"), state = c("PE", "PE", "SP"),
    office = "senator", current_party = c("PT", "PSB", "PT"), mandate_id = "m",
    mandate_role = c("principal", "alternate", "principal"), mandate_role_raw = "x",
    exercise_status = c("serving", "serving", "on_leave"), exercise_status_raw = "x",
    exercise_start = as.Date("2023-02-01"), exercise_end = as.Date(NA),
    status_recorded_at = NA_character_, source_updated_at = NA_character_,
    source = "s", reference = "current_officeholding"))
  saveRDS(list(time = Sys.time(), data = x), file.path(dir, "senado_current_v1.rds"))
  expect_equal(nrow(get_senators(cache_dir = dir)), 2)
  expect_equal(get_senators(state = "pe", party = "pt", cache_dir = dir)$name, "A")
  expect_equal(get_senators(role = "alternate", cache_dir = dir)$name, "B")
  expect_equal(nrow(get_senators(state = "SP", cache_dir = dir)), 0)
})
