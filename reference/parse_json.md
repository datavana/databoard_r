# Parse JSON from a response

Only try to parse JSON if the server actually returned JSON. For
example, on HTTP errors the body may be an HTML error page.

## Usage

``` r
parse_json(resp)
```

## Arguments

- resp:

  The server response as returned by
  [`tasks_run_post()`](https://datavana.github.io/databoard_r/reference/tasks_run_post.md)
  or
  [`tasks_run_get()`](https://datavana.github.io/databoard_r/reference/tasks_run_get.md).

## Value

The parsed JSON object or NULL
