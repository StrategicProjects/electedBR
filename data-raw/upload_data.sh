#!/bin/zsh
# Uploads data-raw/parquet/*.parquet to the Hugging Face dataset used by
# electedBR, then run: Rscript data-raw/elected_years.R
# One-time: pip install -U huggingface_hub (or brew install huggingface-cli); hf auth login
set -euo pipefail
cd "$(dirname "$0")/.."
REPO="mlkwy/electedBR"
hf repo create "$REPO" --repo-type dataset --exist-ok
hf upload "$REPO" data-raw/parquet . --repo-type dataset --include "*.parquet" \
  --commit-message "Elected candidates and alternates from TSE vote files"
hf upload "$REPO" data-raw/README_dataset.md README.md --repo-type dataset
# Files are then served at:
#   https://huggingface.co/datasets/$REPO/resolve/main/elected_2024.parquet
