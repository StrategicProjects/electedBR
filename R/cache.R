# Reads a cached tibble when it is younger than `max_age_hours`; otherwise
# calls `fetch()`, stores the result and keeps an immutable snapshot of it.
# A failed fetch never silently falls back to expired data.
.cached_table <- function(key, fetch, refresh, cache_dir, max_age_hours) {
  .check_flag(refresh, "refresh")
  if (!is.numeric(max_age_hours) || length(max_age_hours) != 1L ||
      is.na(max_age_hours) || max_age_hours < 0)
    stop("`max_age_hours` must be a single non-negative number.", call. = FALSE)
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  path <- file.path(cache_dir, paste0(key, ".rds"))
  if (!refresh && file.exists(path)) {
    item <- tryCatch(readRDS(path), error = function(e) NULL)
    if (!is.null(item) && inherits(item$data, "tbl_df") && inherits(item$time, "POSIXct")) {
      age <- as.numeric(difftime(Sys.time(), item$time, units = "hours"))
      if (is.finite(age) && age >= 0 && age < max_age_hours) return(item$data)
    }
  }
  x <- fetch()
  if (!inherits(x, "tbl_df")) stop("Provider must return a tibble.", call. = FALSE)
  now <- Sys.time()
  x$retrieved_at <- rep(format(now, tz = "UTC", usetz = TRUE), nrow(x))
  item <- list(time = now, data = x)
  tmp <- tempfile(tmpdir = cache_dir)
  on.exit(unlink(tmp), add = TRUE)
  saveRDS(item, tmp)
  if (!file.copy(tmp, path, overwrite = TRUE))
    stop("Could not write to ", cache_dir, ".", call. = FALSE)
  # Snapshots are local observations of the source, not inferred events.
  folder <- file.path(cache_dir, "snapshots", key)
  dir.create(folder, recursive = TRUE, showWarnings = FALSE)
  snapshot <- tempfile(pattern = paste0(format(now, "%Y%m%dT%H%M%S", tz = "UTC"), "_"),
                       tmpdir = folder, fileext = ".rds")
  if (!file.copy(tmp, snapshot)) stop("Could not preserve snapshot.", call. = FALSE)
  x
}

#' Remove cached files
#'
#' Deletes the yearly election files, the cached parliamentary tables and the
#' snapshots stored in `cache_dir`. The next query downloads them again.
#'
#' @param cache_dir Cache directory; the package default is
#'   `tools::R_user_dir("electedBR", "cache")`.
#' @return The number of files removed, invisibly.
#' @examples
#' dir <- file.path(tempdir(), "electedBR-example")
#' dir.create(dir)
#' writeLines("x", file.path(dir, "elected_2024.parquet"))
#' elected_clear_cache(dir)
#' @export
elected_clear_cache <- function(cache_dir = tools::R_user_dir("electedBR", "cache")) {
  if (!dir.exists(cache_dir)) return(invisible(0L))
  files <- list.files(cache_dir, recursive = TRUE, full.names = TRUE, all.files = TRUE,
                      include.dirs = FALSE)
  files <- files[!basename(files) %in% c(".", "..")]
  unlink(files)
  unlink(file.path(cache_dir, "snapshots"), recursive = TRUE)
  invisible(length(files))
}

#' @rdname elected_clear_cache
#' @export
limpar_cache_eleitos <- elected_clear_cache
