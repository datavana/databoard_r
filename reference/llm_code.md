# Automated content coding with an LLM

Submits each row of `data` to the Databoard `coding` task, which asks an
LLM to assign category codes to the text in `col` based on a set of
coding `rules`. The databoard server pre-processes the rules to embed
them in the prompt, and post-processes the LLM answer to split it into
columns for a data frame.

## Usage

``` r
llm_code(data, col, rules = NULL, mode = "single", options = list(), wait = 0)
```

## Arguments

- data:

  A data frame containing the texts to be coded, or a data frame
  previously returned by `llm_code()` whose pending results should be
  fetched.

- col:

  A column in `data` holding the input text. Tidy-evaluation is
  supported (pass the bare column name).

- rules:

  A data frame describing the coding scheme, with the columns
  `category`, `description`, and `example`. One row per category.

- mode:

  Character. Coding mode:

  - `"single"` (default) — return the single best-matching category per
    case.

  - `"multi"` — return a value per category, where `0` = does not apply,
    `1` = applies, `2` = fully applies.

- options:

  A named list of additional options passed to the Databoard server. See
  the databoad server documentation for available options.

- wait:

  Integer. Seconds to wait server-side per case for the task to complete
  before returning.

  - `0` (default): submit all tasks and return immediately with state
    `PENDING`. Fetch results later by calling `llm_code(data)` again.

  - `> 0`: wait up to that many seconds per case for the result.

## Value

The input data frame with the columns `.task_id` and `.task_state`
added. When results are available, they are unnested into additional
result columns (e.g. `llm_result`).

## Details

The function has two modes of operation, dispatched automatically:

- **Submit** — if `data` does *not* yet contain a `.task_id` column, the
  texts in `col` are submitted as new coding tasks (via
  [`da_submit()`](https://datavana.github.io/databoard_r/reference/da_submit.md)).

- **Fetch** — if `data` already contains a `.task_id` column (i.e. it
  was previously returned by `llm_code()`), the function fetches results
  for any tasks that are still pending (via
  [`da_fetch()`](https://datavana.github.io/databoard_r/reference/da_fetch.md)).
  In this case, all other parameters are ignored.

Typical usage is to call `llm_code()` once to submit, and then call it
repeatedly on the returned data frame until all results are in (see
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

[`llm_summarize()`](https://datavana.github.io/databoard_r/reference/llm_summarize.md),
[`llm_prompt()`](https://datavana.github.io/databoard_r/reference/llm_prompt.md),
[`da_submit()`](https://datavana.github.io/databoard_r/reference/da_submit.md),
[`da_fetch()`](https://datavana.github.io/databoard_r/reference/da_fetch.md)\]

## Examples

``` r
if (FALSE) { # \dontrun{
# Log in to the Databoard service (requires valid credentials)
da_login()

# Submit coding tasks
data <- llm_code(songs, text, rules)

# Fetch results: call the same function again with the returned
# data frame as the only argument. Repeat until all results are in.
data <- llm_code(data)

# Inspect the coded results
dplyr::count(data, llm_result)
} # }
```
