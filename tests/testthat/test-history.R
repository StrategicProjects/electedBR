test_that("history preserves official periods and does not infer Chamber intervals", {
  h <- electedBR:::.parse_camara_history(list(list(id = 1, dataHora = "2026-01-01T12:00",
    situacao = "Exercício", condicaoEleitoral = "Suplente",
    descricaoStatus = "Alteração de partido")), "1")
  expect_true(is.na(h$exercise_start))
  expect_identical(h$record_type, "status_record")
  expect_identical(h$exercise_status, "serving")
  j <- list(MandatoParlamentar = list(Parlamentar = list(Codigo = "1", Nome = "A",
    Mandatos = list(Mandato = list(CodigoMandato = "2", DescricaoParticipacao = "1º Suplente",
      Exercicios = list(Exercicio = list(CodigoExercicio = "3", DataInicio = "2026-01-01",
        DataFim = "2026-02-01")))))))
  x <- electedBR:::.parse_senate_history(j, "1")
  expect_equal(x$exercise_end, as.Date("2026-02-01"))
  expect_identical(x$record_type, "service_period")
  expect_identical(x$exercise_status, "unknown")
  expect_error(electedBR:::.parse_senate_history(j, "99"), "identity")
})

test_that("person ids are validated and cached histories are reused", {
  dir <- withr::local_tempdir()
  expect_error(get_service_history("123", cache_dir = dir), "person_id")
  expect_error(get_service_history(c("camara:1", "camara:2"), cache_dir = dir), "person_id")
  h <- electedBR:::.empty_history()
  saveRDS(list(time = Sys.time(), data = h), file.path(dir, "camara_history_v1_1.rds"))
  expect_identical(get_service_history("camara:1", cache_dir = dir),
                   consultar_historico_exercicio("camara:1", cache_dir = dir))
})
