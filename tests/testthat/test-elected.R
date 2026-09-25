test_that("cached files allow offline queries and empty results keep the schema", {
  dir <- withr::local_tempdir()
  seed_cache(dir)
  x <- get_mayors(state = "pe", municipality = "recife", party = "psb", cache_dir = dir)
  expect_s3_class(x, "tbl_df")
  expect_equal(nrow(x), 1)
  expect_identical(x$office, "mayor")
  expect_match(attr(x, "source"), "resultados-2024")
  y <- get_councilors(state = "PE", municipality = "25313", party = c("PT", "PSD"),
                      cache_dir = dir)
  expect_equal(nrow(y), 2)
  z <- get_elected(state = "PE", municipality = "nowhere", cache_dir = dir)
  expect_equal(nrow(z), 0)
  expect_identical(names(z), names(x))
  all <- get_elected(cache_dir = dir)
  expect_equal(nrow(all), 4)
  expect_equal(nrow(get_elected(include_alternates = TRUE, cache_dir = dir)), 5)
  v <- get_elected(office = "vice_mayor", cache_dir = dir)
  expect_identical(v$ticket_candidate_id, "1")
})

test_that("as_of applies office-holding events; successors inherit the office", {
  dir <- withr::local_tempdir()
  seed_cache(dir)
  ev <- events_fixture()
  before <- get_mayors(state = "PE", as_of = "2026-04-01", events = ev, cache_dir = dir)
  expect_identical(before$status_as_of, "no_change_recorded")
  expect_identical(before$office_as_of, "mayor")
  x <- get_elected(state = "PE", office = c("mayor", "vice_mayor"), as_of = "2026-04-03",
                   events = ev, cache_dir = dir)
  expect_identical(x$status_as_of[x$candidate_id == "1"], "resignation")
  expect_equal(x$status_date[x$candidate_id == "1"], as.Date("2026-04-02"))
  # the successor only takes over on successor_date
  expect_identical(x$status_as_of[x$candidate_id == "9"], "no_change_recorded")
  y <- get_elected(state = "PE", office = c("mayor", "vice_mayor"), as_of = as.Date("2026-06-01"),
                   events = ev, cache_dir = dir)
  expect_identical(y$status_as_of[y$candidate_id == "9"], "succession")
  expect_identical(y$office_as_of[y$candidate_id == "9"], "mayor")
  expect_identical(y$status_source[y$candidate_id == "9"], "https://example.org/record")
  expect_identical(y$office[y$candidate_id == "9"], "vice_mayor")
  # a later return cancels the leave
  ev2 <- rbind(ev, transform(ev, event = "leave", date = "2026-08-01",
                             successor_date = "2026-08-01"),
               transform(ev, event = "return", date = "2026-09-01",
                         successor_candidate_id = NA, successor_date = NA))
  z <- get_mayors(state = "PE", as_of = "2026-09-15", events = ev2, cache_dir = dir)
  expect_identical(z$status_as_of, "return")
  expect_identical(consultar_prefeitos(uf = "PE", data_referencia = "2026-09-15", eventos = ev2,
                                       cache_dir = dir), z)
  expect_error(get_mayors(as_of = "not a date", events = ev, cache_dir = dir), "as_of")
  expect_error(get_mayors(as_of = "2026-01-01", events = data.frame(a = 1), cache_dir = dir),
               "events table")
  bad <- ev
  bad$event <- "vacation"
  expect_error(get_mayors(as_of = "2026-01-01", events = bad, cache_dir = dir), "unknown event")
  expect_named(get_officeholding_events(events = ev), c(names(ev)))
})

test_that("year, office and state are validated before any download", {
  dir <- withr::local_tempdir()
  expect_error(get_elected(year = 1999, cache_dir = dir), "elected_years")
  expect_error(get_elected(year = 2024, office = "senator", cache_dir = dir), "do not match")
  expect_error(get_elected(year = 2022, office = "mayor", cache_dir = dir), "do not match")
  expect_error(get_elected(year = 2024, office = "vice_governor", cache_dir = dir), "do not match")
  expect_error(get_elected(year = 2024, office = "king", cache_dir = dir), "Invalid `office`")
  expect_error(get_elected(year = 2024, state = "XX", cache_dir = dir), "Invalid state")
  expect_error(get_elected(year = 2024, state = "DF", cache_dir = dir), "Invalid state")
  expect_error(get_elected(year = 2022, office = "senator", municipality = "Recife",
                           cache_dir = dir), "municipal offices only")
  expect_error(get_elected(year = 2024, refresh = NA, cache_dir = dir), "refresh")
  expect_error(get_elected(year = 2024, party = NA, cache_dir = dir), "party")
  expect_length(list.files(dir), 0)
})

test_that("English and Portuguese interfaces return identical tibbles", {
  dir <- withr::local_tempdir()
  seed_cache(dir)
  a <- get_mayors(state = "PE", municipality = "Recife", party = "PSB", cache_dir = dir)
  b <- consultar_prefeitos(uf = "PE", municipio = "Recife", partido = "PSB", cache_dir = dir)
  expect_identical(a, b)
  expect_identical(get_councilors(state = "PE", cache_dir = dir),
                   consultar_vereadores(uf = "PE", cache_dir = dir))
  expect_identical(get_elected(state = "PE", cache_dir = dir),
                   consultar_eleitos(uf = "PE", cache_dir = dir))
  expect_identical(get_elected(office = "councilor", cache_dir = dir),
                   consultar_eleitos(cargo = "Vereador", cache_dir = dir))
  expect_identical(get_elected(office = "councilor", cache_dir = dir),
                   consultar_eleitos(cargo = "councilor", cache_dir = dir))
  expect_identical(get_elected(office = "vice_mayor", cache_dir = dir),
                   consultar_eleitos(cargo = "Vice-Prefeito", cache_dir = dir))
  expect_error(consultar_eleitos(cargo = "REI", cache_dir = dir), "Invalid `cargo`")
})

test_that("downloads are verified against the index and served from a mirror", {
  dir <- withr::local_tempdir()
  mirror <- withr::local_tempdir()
  seed_cache(mirror)
  path <- file.path(mirror, "elected_2024.parquet")
  row <- data.frame(year = 2024L, file = "elected_2024.parquet",
                    url = "https://example.invalid/elected_2024.parquet",
                    bytes = as.numeric(file.size(path)),
                    md5 = unname(tools::md5sum(path)), stringsAsFactors = FALSE)
  src <- path
  local_mocked_bindings(req_perform = function(req, path, ...) file.copy(src, path),
                        .package = "httr2")
  expect_message(got <- electedBR:::.elected_file(row, dir, base_url = "https://mirror.invalid/x/"),
                 "mirror.invalid/x/elected_2024.parquet")
  expect_true(file.exists(got))
  expect_identical(unname(tools::md5sum(got)), row$md5)
  # cached: no message, no download
  expect_silent(electedBR:::.elected_file(row, dir))
  row$md5 <- "0"
  expect_error(suppressMessages(electedBR:::.elected_file(row, dir, refresh = TRUE)), "MD5")
  row$bytes <- 1
  expect_error(suppressMessages(electedBR:::.elected_file(row, dir, refresh = TRUE)), "size")
  expect_length(list.files(dir, pattern = "part$"), 0)
})

test_that("the shipped index is consistent", {
  expect_s3_class(elected_years, "data.frame")
  expect_true(all(c("year", "kind", "file", "url", "bytes", "md5") %in% names(elected_years)))
  expect_false(anyDuplicated(elected_years$year) > 0)
  expect_identical(elected_years$file, sprintf("elected_%d.parquet", elected_years$year))
  expect_identical(elected_years$kind,
                   ifelse(elected_years$year %% 4 == 2, "general", "municipal"))
})

test_that("elected_clear_cache removes files and snapshots", {
  dir <- withr::local_tempdir()
  seed_cache(dir)
  dir.create(file.path(dir, "snapshots", "k"), recursive = TRUE)
  writeLines("x", file.path(dir, "snapshots", "k", "a.rds"))
  n <- elected_clear_cache(dir)
  expect_equal(n, 2L)
  expect_length(list.files(dir, recursive = TRUE), 0)
  expect_equal(limpar_cache_eleitos(file.path(dir, "missing")), 0L)
})
