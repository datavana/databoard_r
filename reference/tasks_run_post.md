# Submit a single task to the Databoard API (low level)

Sends one `POST /tasks/run` request to the Databoard API. This is the
underlying request helper used by
[`da_submit()`](https://datavana.github.io/databoard_r/reference/da_submit.md);
end users typically don't need to call it directly.

## Usage

``` r
tasks_run_post(task, input, options, wait = 0)
```

## Arguments

- task:

  Character. The task type (e.g. `"summarize"`, `"coding"`,
  `"annotate"`, `"triples"`).

- input:

  Character. The input text for the task. Must be non-empty.

- options:

  A named list of task-specific options passed to the API.

- wait:

  Integer. Seconds to wait server-side for the task to complete before
  returning. Defaults to `0`.

## Value

The server response

## Details

Requires prior authentication via
[`da_login()`](https://datavana.github.io/databoard_r/reference/da_login.md);
the access token is read from the `DATABOARD_ACCESSTOKEN` environment
variable. Stops with an informative error if the token is missing or the
HTTP status is not 2xx.
