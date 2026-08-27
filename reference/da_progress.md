# Summarise task states of a Databoard data frame

Returns (and optionally prints) a summary of how many tasks are in each
state (e.g. `PENDING`, `SUCCESS`, `FAILURE`). The formatted message
shows the percentage per state on a single line, with colour coding.

## Usage

``` r
da_progress(data, message = FALSE)
```

## Arguments

- data:

  A data frame containing a `.task_state` column (as produced by
  [`da_submit()`](https://datavana.github.io/databoard_r/reference/da_submit.md)
  /
  [`da_fetch()`](https://datavana.github.io/databoard_r/reference/da_fetch.md)).

- message:

  Logical. If `TRUE`, prints a nicely formatted, colourised one-line
  summary via
  [`cli::cli_inform()`](https://cli.r-lib.org/reference/cli_abort.html)
  and returns the counts invisibly. If `FALSE` (default), just returns
  the counts.

## Value

A named list with `TOTAL` (the total number of rows) and one entry per
observed task state.
