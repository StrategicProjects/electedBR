---
license: other
license_name: tse-open-data
license_link: https://dadosabertos.tse.jus.br
language:
  - pt
pretty_name: Candidates elected in Brazilian elections (TSE), 2018-2024
tags:
  - brazil
  - elections
  - politics
size_categories:
  - 100K<n<1M
configs:
  - config_name: default
    data_files: "elected_*.parquet"
---

# Candidates elected in Brazilian elections, 2018-2024

One Parquet file per election year (`elected_2018.parquet` ... `elected_2024.parquet`)
derived from the *votação nominal por município e zona* files of the Superior
Electoral Court open data portal (TSE): <https://dadosabertos.tse.jus.br/>.

Each row is one candidate in one election (`election_id`), with votes summed over
electoral zones (and over municipalities for statewide offices) and the last round
kept. Rows with `election_status = "SUPLENTE"` are the alternates classified by the
TSE; the other rows are the elected candidates. Municipal years (2020, 2024) hold
mayors, deputy mayors and councilors; general years (2018, 2022) hold senators and
federal, state and district deputies. Presidents and governors are not included.

Columns: `year`, `election_id`, `round`, `state`, `municipality_tse_id`, `municipality`,
`office`, `candidate_id`, `name`, `ballot_name`, `party_at_election`, `election_status`,
`votes`, `reference`.

These files back the R package [electedBR](https://github.com/StrategicProjects/electedBR)
(`electedBR::get_elected()`), which also documents the consolidation rules
(`electedBR::normalize_elected()`). Maintained by André Leite.
