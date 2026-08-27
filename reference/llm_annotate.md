# Automated annotation with an LLM

Submits each row of `data` to the Databoard `annotate` task, which asks
an LLM to annotate the text in `col` using `rules`. The server
post-processes the answer and returns tabular output columns.

## Usage

``` r
llm_annotate(data, col, rules, options = list(), wait = 0)
```

## Arguments

- data:

  A data frame containing the texts to be annotated, or a data frame
  previously returned by `llm_annotate()` whose pending results should
  be fetched.

- col:

  A column in `data` holding the input text. Tidy-evaluation is
  supported (pass the bare column name).

- rules:

  Required in submit mode. A data frame that is converted to an array of
  dicts with keys `category`, `description`, and `example`. The
  `description` is used to identify text segments. The `example` should
  contain comma-separated text segments that match the rule. The
  `category` is used as the `value` attribute in the annotation output.

- options:

  A named list of additional options passed to the Databoard server. See
  the databoad server documentation for available options.

- wait:

  Integer. Seconds to wait server-side per case for the task to complete
  before returning.

  - `0` (default): submit all tasks and return immediately with state
    `PENDING`. Fetch results later by calling `llm_annotate(data)`
    again.

  - `> 0`: wait up to that many seconds per case for the result.

## Value

The input data frame with the columns `.task_id` and `.task_state`
added. When results are available, they are unnested into additional
result columns (e.g. `llm_result`). For annotation tasks, `llm_annos` is
added as a list-column with one data frame per case containing `value`
and `segment`.

## Details

The function has two modes of operation, dispatched automatically:

- **Submit** - if `data` does *not* yet contain a `.task_id` column, the
  texts in `col` are submitted as new annotation tasks (via
  [`da_submit()`](https://datavana.github.io/databoard_r/reference/da_submit.md)).

- **Fetch** - if `data` already contains a `.task_id` column (i.e. it
  was previously returned by `llm_annotate()`), the function fetches
  results for any tasks that are still pending (via
  [`da_fetch()`](https://datavana.github.io/databoard_r/reference/da_fetch.md)).
  In this case, all other parameters are ignored.

To customize prompts, pass `options$prompts$system` and/or
`options$prompts$user`.

## See also

[`llm_prompt()`](https://datavana.github.io/databoard_r/reference/llm_prompt.md),
[`llm_code()`](https://datavana.github.io/databoard_r/reference/llm_code.md),
[`llm_summarize()`](https://datavana.github.io/databoard_r/reference/llm_summarize.md),
[`da_submit()`](https://datavana.github.io/databoard_r/reference/da_submit.md),
[`da_fetch()`](https://datavana.github.io/databoard_r/reference/da_fetch.md)

## Examples

``` r
if (FALSE) { # \dontrun{
anno_rules <- tibble::tribble(
  ~category, ~description, ~example,
  "PERSON", "Names of people", "John Doe, Jane Roe",
  "PLACE", "Names of places", "Berlin, New York"
)

# Submit
results <- llm_annotate(movies, abstract, anno_rules)

# Fetch pending tasks
results <- llm_annotate(results)

# Inspect annotations
head(results$llm_result)
results$llm_annos[[1]]
} # }
```
