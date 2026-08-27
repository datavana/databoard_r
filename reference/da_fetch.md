# Fetch results for previously submitted tasks

Iterates over rows of `data` and retrieves results for any task that is
still in the `PENDING` state. Newly received results overwrite the
corresponding rows' `.task_state` and `.task_result` values, and are
unnested into regular columns.

## Usage

``` r
da_fetch(data, wait = 10)
```

## Arguments

- data:

  A data frame previously produced by
  [`da_submit()`](https://datavana.github.io/databoard_r/reference/da_submit.md).
  Must contain a `.task_id` column.

- wait:

  Integer. Seconds to wait server-side per request for the task to
  complete before returning. Defaults to `10`.

## Value

The input data frame with updated `.task_state` values and unnested
result columns.
