## Builds the `elected_years` index shipped in data/elected_years.rda from the
## files in data-raw/parquet/ (gitignored; rebuilt by data-raw/build_elected.R).
## To move the data to another host, change `base_url`, upload the files
## (data-raw/upload_data.sh) and re-run this script.

base_url <- "https://huggingface.co/datasets/mlkwy/electedBR/resolve/main"

files <- sort(list.files("data-raw/parquet", pattern = "^elected_\\d{4}\\.parquet$"))
stopifnot(length(files) > 0)
paths <- file.path("data-raw/parquet", files)
year <- as.integer(sub("^elected_(\\d{4})\\.parquet$", "\\1", files))

elected_years <- data.frame(
  year  = year,
  kind  = ifelse(year %% 4L == 2L, "general", "municipal"),
  file  = files,
  url   = paste0(base_url, "/", files),
  bytes = as.numeric(file.size(paths)),
  md5   = unname(tools::md5sum(paths)),
  rows  = vapply(paths, function(p) as.numeric(nanoparquet::read_parquet_info(p)$num_rows), 1),
  built = as.Date(file.mtime(paths)),
  stringsAsFactors = FALSE
)
rownames(elected_years) <- NULL
print(elected_years)
usethis::use_data(elected_years, overwrite = TRUE)
