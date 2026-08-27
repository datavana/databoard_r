# Extract task metadata and result into a data frame row

Internal helper that writes the fields of an API response `body` into
row `no` of `data`. Creates the columns `.task_id`, `.task_state`, and
`.task_result` on the fly if they don't yet exist.

## Usage

``` r
da_extract(data, resp, no)
```

## Arguments

- data:

  A data frame to be updated.

- resp:

  The server response as returned by
  [`tasks_run_post()`](https://datavana.github.io/databoard_r/reference/tasks_run_post.md)
  or
  [`tasks_run_get()`](https://datavana.github.io/databoard_r/reference/tasks_run_get.md).

- no:

  Integer. Row index in `data` to write to.

## Value

The updated data frame.
