# Check whether a response was successful (code 20x)

Stops with an error message if DATABOARD_SILENT is not TRUE.

## Usage

``` r
check_succesful(resp)
```

## Arguments

- resp:

  The server response as returned by
  [`tasks_run_post()`](https://datavana.github.io/databoard_r/reference/tasks_run_post.md)
  or
  [`tasks_run_get()`](https://datavana.github.io/databoard_r/reference/tasks_run_get.md).

## Value

A boolean indicating whether the response was succesful
