# Check whether a response contains status code 401

Stops with an error message if DATABOARD_SILENT is not TRUE.

## Usage

``` r
da_authorized(resp)
```

## Arguments

- resp:

  The server response as returned by
  [`tasks_run_post()`](https://datavana.github.io/databoard_r/reference/tasks_run_post.md)
  or
  [`tasks_run_get()`](https://datavana.github.io/databoard_r/reference/tasks_run_get.md).

## Value

A boolean indicating whether the user is authorized.

## See also

[`da_login()`](https://datavana.github.io/databoard_r/reference/da_login.md)
