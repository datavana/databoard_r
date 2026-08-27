# Automated content summarisation with an LLM

Submits each row of `data` to the Databoard `summarize` task, which asks
an LLM to summarise the text in `col`. Optionally, a `rules` data frame
can be provided to produce structured, per-category summaries. The
databoard server pre-processes the rules to embed them in the prompt,
and post-processes the LLM answer to split it into columns for a data
frame.

## Usage

``` r
llm_summarize(data, col, rules, options = list(), wait = 0)
```

## Arguments

- data:

  A data frame containing the texts to be summarised, or a data frame
  previously returned by `llm_summarize()` whose pending results should
  be fetched.

- col:

  A column in `data` holding the input text. Tidy-evaluation is
  supported (pass the bare column name).

- rules:

  Optional. Provide rules to produce multiple summaries. A data frame
  with the columns `category`, `description`, and `example`. One output
  is created for each category. The description should prompt what to
  summarize. Optionally, add an example of the expected output.

- options:

  A named list of additional options passed to the Databoard server.

- wait:

  Integer. Seconds to wait server-side per case for the task to complete
  before returning.

  - `0` (default): submit all tasks and return immediately with state
    `PENDING`. Fetch results later by calling `llm_summarize(data)`
    again.

  - `> 0`: wait up to that many seconds per case for the result.

## Value

The input data frame with the columns `.task_id` and `.task_state`
added. When results are available, they are unnested into additional
result columns (e.g. `llm_result`).

## Details

The function has two modes of operation, dispatched automatically:

- **Submit** — if `data` does *not* yet contain a `.task_id` column, the
  texts in `col` are submitted as new summarisation tasks (via
  [`da_submit()`](https://datavana.github.io/databoard_r/reference/da_submit.md)).

- **Fetch** — if `data` already contains a `.task_id` column (i.e. it
  was previously returned by `llm_summarize()`), the function fetches
  results for any tasks that are still pending (via
  [`da_fetch()`](https://datavana.github.io/databoard_r/reference/da_fetch.md)).
  In this case, all other parameters are ignored.

Typical usage is to call `llm_summarize()` once to submit, and then call
it repeatedly on the returned data frame until all results are in (see
[`da_finished()`](https://datavana.github.io/databoard_r/reference/da_finished.md)).

To customize the prompts, provide them in the options:

    options = list(
      prompts = list(
        system = "YOURSYSTEMPROMPT",
        user = "YOURUSERPROMPT"
      )
    )

If the prompts are given as character vectors, their elements are
collapsed using a line break (as in
[`llm_prompt()`](https://datavana.github.io/databoard_r/reference/llm_prompt.md)).

If present in the prompts, the placeholder `{{text}}` is replaced by the
value of the current case. The placeholder `{{rules}}` is replaced by a
rule book generated from the rules data frame.

See the databoard documentation for further options.

## See also

[`llm_prompt()`](https://datavana.github.io/databoard_r/reference/llm_prompt.md),
[`llm_code()`](https://datavana.github.io/databoard_r/reference/llm_code.md),
[`da_submit()`](https://datavana.github.io/databoard_r/reference/da_submit.md),
[`da_fetch()`](https://datavana.github.io/databoard_r/reference/da_fetch.md)\]

## Examples

``` r
if (FALSE) { # \dontrun{
# Log in to the Databoard service (requires valid credentials)
da_login()

# Submit summarisation tasks
data <- llm_summarize(songs, text)

# Fetch results: call the same function again with the returned
# data frame as the only argument. Repeat until all results are in.
data <- llm_summarize(data)

# Inspect the summaries
head(data$llm_result)
} # }
```
