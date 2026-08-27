# Retrieve a single task result from the Databoard API (low level)

Sends one `GET /tasks/run/{task_id}` request to the Databoard API. This
is the underlying request helper used by
[`da_fetch()`](https://datavana.github.io/databoard_r/reference/da_fetch.md);
end users typically don't need to call it directly.

## Usage

``` r
tasks_run_get(task_id, wait = 0)
```

## Arguments

- task_id:

  Character. The identifier of a previously submitted task.

- wait:

  Integer. Seconds to wait server-side for the task to complete before
  returning. Defaults to `0`.

## Value

The server response.

## Details

Requires prior authentication via
[`da_login()`](https://datavana.github.io/databoard_r/reference/da_login.md);
the access token is read from the `DATABOARD_ACCESSTOKEN` environment
variable. Stops with an informative error if the token is missing or the
HTTP status is not 2xx.
