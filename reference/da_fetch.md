# Fetch results for previously submitted tasks

Retrieves results for all tasks in `data` that are still in the
`PENDING` state. Newly received results overwrite the corresponding
rows' `.task_state` and `.task_result` values, and are unnested into
regular columns.

## Usage

``` r
da_fetch(data, wait = 10, poll = FALSE, interval = 5, timeout = Inf)
```

## Arguments

- data:

  A data frame previously produced by
  [`da_submit()`](https://datavana.github.io/databoard_r/reference/da_submit.md).
  Must contain a `.task_id` column.

- wait:

  Integer. Seconds to wait server-side per request for the task to
  complete before returning. Defaults to `10`.

- poll:

  Logical. If `FALSE` (default), make a single pass over pending tasks.
  If `TRUE`, repeat until no task is pending, `timeout` is reached, or
  the user interrupts.

- interval:

  Numeric. Seconds to pause between polling rounds. Only used when
  `poll = TRUE`. Defaults to `5`.

- timeout:

  Numeric. Maximum total polling time in seconds. Defaults to `Inf`
  (poll until done or interrupted).

## Value

The input data frame with updated `.task_state` values and unnested
result columns. If polling was interrupted or timed out, the results
received so far are returned.

## Details

With `poll = TRUE`, the function keeps fetching in rounds until no task
is pending, the `timeout` is reached, or the user interrupts. After each
round it prints a summary of task states and counts down to the next
round.

## Interrupting

Press `Esc` (RStudio, Positron) or `Ctrl+C` (terminal) at any time to
stop polling. The interrupt is caught, so the results collected so far
are unnested and returned normally, e.g.
`res <- da_fetch(df, poll = TRUE)` still assigns `res`. Call
`da_fetch()` again on the result to resume.

## Examples

``` r
if (FALSE) { # \dontrun{
res <- df |>
  da_submit(text, rules) |>
  da_fetch(poll = TRUE)
} # }
```
