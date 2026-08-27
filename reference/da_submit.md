# Submit tasks to the Databoard service

Submits one Databoard task per row of `data`, using the values of `col`
as input. Task metadata (id, state) and results are stored back into
`data` in the special columns `.task_id`, `.task_state`, and
`.task_result`. After submission, results are unnested into regular
columns and a progress summary is printed.

## Usage

``` r
da_submit(data, col, task, options, wait = 0)
```

## Arguments

- data:

  A data frame containing the input data.

- col:

  A column in `data` holding the text input. Tidy-evaluation is
  supported (i.e. pass the bare column name).

- task:

  Character. The task the LLM is supposed to perform (e.g.
  `"summarize"`, `"coding"`, `"annotate"`, `"triples"`).

- options:

  A named list of task-specific options passed to the API (e.g. coding
  rules, model parameters).

- wait:

  Integer. Seconds to wait server-side for immediate completion of each
  task before returning. `0` (default) returns immediately with a
  `PENDING` state; larger values reduce the need for later
  [`da_fetch()`](https://datavana.github.io/databoard_r/reference/da_fetch.md)
  calls.

## Value

The input data frame with additional columns: `.task_id`, `.task_state`,
and one column per field returned by the task (unnested from
`.task_result`).

## Details

Tasks are submitted sequentially, one per row. The function stops
immediately if a submission fails.
