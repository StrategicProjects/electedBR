# Precompile the network-dependent vignette.
#
# The vignette downloads a yearly file from Hugging Face and queries the
# Senate API, so it cannot be built on CRAN or CI. Following the rOpenSci
# pattern (https://ropensci.org/blog/2019/12/08/precompute-vignettes/), the
# executable source lives in electedBR.Rmd.orig; this script knits it locally
# into the electedBR.Rmd that ships with the package, with output baked in.
# Run it from the package root after installing the development version
# (R CMD INSTALL .), then commit the regenerated .Rmd.
#
# Usage: Rscript vignettes/precompile.R

old <- setwd("vignettes")
on.exit(setwd(old), add = TRUE)
knitr::knit("electedBR.Rmd.orig", output = "electedBR.Rmd")
