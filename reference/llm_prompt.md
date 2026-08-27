# Prompt an LLM with custom prompts

Sends a custom prompt to the LLM for each row of `data` and returns the
raw model output. Unlike
[`llm_code()`](https://datavana.github.io/databoard_r/reference/llm_code.md)
and
[`llm_summarize()`](https://datavana.github.io/databoard_r/reference/llm_summarize.md),
which apply task-specific pre- and post-processing on the Databoard
server, `llm_prompt()` bypasses all post-processing and hands back the
answer as-is in a single `llm_result` column. Use this function when you
want full control over the prompts and the output format.

## Usage

``` r
llm_prompt(
  data,
  col,
  rules = NULL,
  prompt.system = NULL,
  prompt.user = NULL,
  options = list(),
  wait = 0
)
```

## Arguments

- data:

  A data frame containing the texts to be processed, or a data frame
  previously returned by `llm_prompt()` whose pending results should be
  fetched.

- col:

  A column in `data` holding the input text. Tidy-evaluation is
  supported (pass the bare column name).

- rules:

  Optional. A data frame with the columns `category`, `description`, and
  `example` (one row per category). If provided, a rule book is
  generated from it and made available via the `{{rules}}` placeholder
  in the prompts.

- prompt.system:

  The system prompt. Character vector; multiple elements are collapsed
  with a line break. May contain the `{{text}}` and `{{rules}}`
  placeholders.

- prompt.user:

  The user prompt. Character vector; multiple elements are collapsed
  with a line break. May contain the `{{text}}` and `{{rules}}`
  placeholders. In most cases, this is where you want to place
  `{{text}}`.

- options:

  A named list of additional options passed to the Databoard server. See
  the Databoard server documentation for available options.

- wait:

  Integer. Seconds to wait server-side per case for the task to complete
  before returning.

  - `0` (default): submit all tasks and return immediately with state
    `PENDING`. Fetch results later by calling `llm_prompt(data)` again.

  - `> 0`: wait up to that many seconds per case for the result.

## Value

The input data frame with the columns `.task_id` and `.task_state`
added. When results are available, the raw LLM answer for each case is
returned in the `llm_result` column (as a character string; no parsing
or splitting is performed).

## Details

Internally, `llm_prompt()` uses the Databoard `summarize` workflow but
overrides its prompts with the ones you provide.

## Placeholders

The prompts may contain the following placeholders, which are filled in
per case before the prompt is sent to the LLM:

- `{{text}}` — replaced by the value of `col` for the current row.

- `{{rules}}` — replaced by a rule book generated from the `rules` data
  frame (only useful if `rules` is provided).

## Submit and fetch

Like the other `llm_*()` wrappers, `llm_prompt()` has two modes of
operation, dispatched automatically:

- **Submit** — if `data` does *not* yet contain a `.task_id` column, the
  texts in `col` are submitted as new tasks (via
  [`da_submit()`](https://datavana.github.io/databoard_r/reference/da_submit.md)).

- **Fetch** — if `data` already contains a `.task_id` column (i.e. it
  was previously returned by `llm_prompt()`), the function fetches
  results for any tasks that are still pending (via
  [`da_fetch()`](https://datavana.github.io/databoard_r/reference/da_fetch.md)).
  In this case, all other parameters are ignored.

Typical usage is to call `llm_prompt()` once to submit, and then call it
repeatedly on the returned data frame until all results are in (see
[`da_finished()`](https://datavana.github.io/databoard_r/reference/da_finished.md)).

## See also

[`llm_summarize()`](https://datavana.github.io/databoard_r/reference/llm_summarize.md),
[`llm_code()`](https://datavana.github.io/databoard_r/reference/llm_code.md),
[`da_submit()`](https://datavana.github.io/databoard_r/reference/da_submit.md),
[`da_fetch()`](https://datavana.github.io/databoard_r/reference/da_fetch.md),
[`da_finished()`](https://datavana.github.io/databoard_r/reference/da_finished.md)

## Examples

``` r
if (FALSE) { # \dontrun{
da_login()

# Submit and wait up to 10 seconds per case
data <- llm_prompt(
  songs, text,
  prompt.system = "Output a comma separated list of topics. Just the list, nothing else.",
  prompt.user = "{{text}}",
  wait = 10
)

# If any tasks are still pending, fetch them later
data <- llm_prompt(data)

# Inspect the raw answers
head(data$llm_result)
} # }
```
