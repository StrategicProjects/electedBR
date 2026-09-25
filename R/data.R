#' Yearly files of elected candidates
#'
#' Index of the Parquet files distributed by the package, one per election
#' year, with the URL they are downloaded from and the checksums used to verify
#' the download. Used internally by [get_elected()]; the host can be overridden
#' with the `electedBR.base_url` option or the `base_url` argument.
#'
#' Each file is the output of [normalize_elected()] with
#' `include_alternates = TRUE` applied to the TSE *votação nominal por
#' município e zona* dataset of that year, so it holds both the elected
#' candidates and the alternates classified in the TSE file.
#'
#' @format A data frame with one row per year and the columns:
#' \describe{
#'   \item{year}{Election year.}
#'   \item{kind}{`"municipal"` (mayors, deputy mayors and councilors) or
#'     `"general"` (senators and federal, state and district deputies).}
#'   \item{file}{File name (for example `elected_2024.parquet`).}
#'   \item{url}{Download URL of the file.}
#'   \item{bytes}{File size in bytes, used to check the download.}
#'   \item{md5}{MD5 checksum of the file.}
#'   \item{rows}{Number of rows (elected candidates plus alternates).}
#'   \item{built}{Date on which the file was generated from the TSE data.}
#' }
#' @source Derived from the TSE open data portal,
#'   <https://dadosabertos.tse.jus.br/>; files hosted at
#'   <https://huggingface.co/datasets/mlkwy/electedBR>.
#' @examples
#' elected_years
"elected_years"
