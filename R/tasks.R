#
# Wrappers for specific tasks
#

#' Prompt an LLM with custom prompts
#'
#' Sends a custom prompt to the LLM for each row of `data` and returns the raw
#' model output. Unlike [llm_code()] and [llm_summarize()], which apply
#' task-specific pre- and post-processing on the Databoard server,
#' `llm_prompt()` bypasses all post-processing and hands back the answer as-is
#' in a single `llm_result` column. Use this function when you want full
#' control over the prompts and the output format.
#'
#' Internally, `llm_prompt()` uses the Databoard `summarize` workflow but
#' overrides its prompts with the ones you provide.
#'
#' # Placeholders
#'
#' The prompts may contain the following placeholders, which are filled in
#' per case before the prompt is sent to the LLM:
#'
#' * `{{text}}` — replaced by the value of `col` for the current row.
#' * `{{rules}}` — replaced by a rule book generated from the `rules` data
#'   frame (only useful if `rules` is provided).
#'
#' # Submit and fetch
#'
#' Like the other `llm_*()` wrappers, `llm_prompt()` has two modes of
#' operation, dispatched automatically:
#'
#' * **Submit** — if `data` does *not* yet contain a `.task_id` column, the
#'   texts in `col` are submitted as new tasks (via [da_submit()]).
#' * **Fetch** — if `data` already contains a `.task_id` column (i.e. it was
#'   previously returned by `llm_prompt()`), the function fetches results for
#'   any tasks that are still pending (via [da_fetch()]). In this case, all
#'   other parameters are ignored.
#'
#' Typical usage is to call `llm_prompt()` once to submit, and then call it
#' repeatedly on the returned data frame until all results are in (see
#' [da_finished()]).
#'
#' @param data A data frame containing the texts to be processed, or a data
#'   frame previously returned by `llm_prompt()` whose pending results should
#'   be fetched.
#' @param col A column in `data` holding the input text. Tidy-evaluation is
#'   supported (pass the bare column name).
#' @param rules Optional. A data frame with the columns `category`,
#'   `description`, and `example` (one row per category). If provided, a rule
#'   book is generated from it and made available via the `{{rules}}`
#'   placeholder in the prompts.
#' @param prompt.system The system prompt. Character vector; multiple elements
#'   are collapsed with a line break. May contain the `{{text}}` and
#'   `{{rules}}` placeholders.
#' @param prompt.user The user prompt. Character vector; multiple elements are
#'   collapsed with a line break. May contain the `{{text}}` and `{{rules}}`
#'   placeholders. In most cases, this is where you want to place `{{text}}`.
#' @param options A named list of additional options passed to the Databoard
#'   server. See the Databoard server documentation for available options.
#' @param wait Integer. Seconds to wait server-side per case for the task to
#'   complete before returning.
#'   * `0` (default): submit all tasks and return immediately with state
#'     `PENDING`. Fetch results later by calling `llm_prompt(data)` again.
#'   * `> 0`: wait up to that many seconds per case for the result.
#'
#' @return The input data frame with the columns `.task_id` and `.task_state`
#'   added. When results are available, the raw LLM answer for each case is
#'   returned in the `llm_result` column (as a character string; no parsing or
#'   splitting is performed).
#'
#' @seealso [llm_summarize()], [llm_code()], [da_submit()], [da_fetch()],
#'   [da_finished()]
#'
#' @examples
#' \dontrun{
#' da_login()
#'
#' # Submit and wait up to 10 seconds per case
#' data <- llm_prompt(
#'   songs, text,
#'   prompt.system = "Output a comma separated list of topics. Just the list, nothing else.",
#'   prompt.user = "{{text}}",
#'   wait = 10
#' )
#'
#' # If any tasks are still pending, fetch them later
#' data <- llm_prompt(data)
#'
#' # Inspect the raw answers
#' head(data$llm_result)
#' }
#'
#' @export
llm_prompt <- function(data, col, rules = NULL, prompt.system = NULL, prompt.user = NULL, options = list(), wait = 0) {

  if (".task_id" %in% colnames(data)) {
    return (da_fetch(data))
  }

  if (!missing(rules)) {
    options$rules <- purrr::transpose(rules)
  }

  options$mode <- "summarize"
  options$prompts <- list(
    system = paste0(prompt.system, collapse = "\n"),
    user = paste0(prompt.user, collapse = "\n")
  )

  da_submit(data, {{ col }}, "summarize", options, wait)

}


#' Automated content coding with an LLM
#'
#' Submits each row of `data` to the Databoard `coding` task, which asks an
#' LLM to assign category codes to the text in `col` based on a set of coding
#' `rules`. The databoard server pre-processes the rules to embed them in the prompt,
#' and post-processes the LLM answer to split it into columns for a data frame.
#'
#' The function has two modes of operation, dispatched automatically:
#'
#' * **Submit** — if `data` does *not* yet contain a `.task_id` column, the
#'   texts in `col` are submitted as new coding tasks (via [da_submit()]).
#' * **Fetch** — if `data` already contains a `.task_id` column (i.e. it was
#'   previously returned by `llm_code()`), the function fetches results for
#'   any tasks that are still pending (via [da_fetch()]). In this case,
#'   all other parameters are ignored.
#'
#' Typical usage is to call `llm_code()` once to submit, and then call it
#' repeatedly on the returned data frame until all results are in (see
#' [da_finished()]).
#'
#' To customize the prompts, provide them in the options:
#'
#' ```
#' options = list(
#'   prompts = list(
#'     system = "YOURSYSTEMPROMPT",
#'     user = "YOURUSERPROMPT"
#'   )
#' )
#' ```
#'
#' If the prompts are given as character vectors, their elements are collapsed
#' using a line break (as in [llm_prompt()]).
#'
#' If present in the prompts, the placeholder `{{text}}` is replaced by the value of the current case.
#' The placeholder `{{rules}}` is replaced by a rule book generated from the rules data frame.
#'
#' See the databoard documentation for further options.
#'
#' @param data A data frame containing the texts to be coded, or a data frame
#'   previously returned by `llm_code()` whose pending results should be
#'   fetched.
#' @param col A column in `data` holding the input text. Tidy-evaluation is
#'   supported (pass the bare column name).
#' @param rules A data frame describing the coding scheme, with the columns
#'   `category`, `description`, and `example`. One row per category.
#' @param mode Character. Coding mode:
#'   * `"single"` (default) — return the single best-matching category per case.
#'   * `"multi"` — return a value per category, where
#'     `0` = does not apply, `1` = applies, `2` = fully applies.
#' @param options A named list of additional options passed to the Databoard
#'   server. See the databoad server documentation for available options.
#' @param wait Integer. Seconds to wait server-side per case for the task to
#'   complete before returning.
#'   * `0` (default): submit all tasks and return immediately with state
#'     `PENDING`. Fetch results later by calling `llm_code(data)` again.
#'   * `> 0`: wait up to that many seconds per case for the result.
#'
#' @return The input data frame with the columns `.task_id` and `.task_state`
#'   added. When results are available, they are unnested into additional
#'   result columns (e.g. `llm_result`).
#'
#' @seealso [llm_summarize()], [llm_prompt()], [da_submit()], [da_fetch()]]
#'
#' @examples
#' \dontrun{
#' # Log in to the Databoard service (requires valid credentials)
#' da_login()
#'
#' # Submit coding tasks
#' data <- llm_code(songs, text, rules)
#'
#' # Fetch results: call the same function again with the returned
#' # data frame as the only argument. Repeat until all results are in.
#' data <- llm_code(data)
#'
#' # Inspect the coded results
#' dplyr::count(data, llm_result)
#' }
#'
#' @export
llm_code <- function(data, col, rules = NULL, mode = "single", options = list(), wait = 0) {

  if (".task_id" %in% colnames(data)) {
    return (da_fetch(data))
  }

  options$rules <- purrr::transpose(rules)
  options$mode <- mode

  if (!is.null(options$prompts$system)) {
    options$prompts$system <- paste0(options$prompts$system, collapse = "\n")
  }
  if (!is.null(options$prompts$user)) {
    options$prompts$user <- paste0(options$prompts$user, collapse = "\n")
  }

  da_submit(data, {{ col }}, "coding", options, wait)

}

#' Automated content summarisation with an LLM
#'
#' Submits each row of `data` to the Databoard `summarize` task, which asks
#' an LLM to summarise the text in `col`. Optionally, a `rules` data frame
#' can be provided to produce structured, per-category summaries.
#' The databoard server pre-processes the rules to embed them in the prompt,
#' and post-processes the LLM answer to split it into columns for a data frame.
#'
#' The function has two modes of operation, dispatched automatically:
#'
#' * **Submit** — if `data` does *not* yet contain a `.task_id` column, the
#'   texts in `col` are submitted as new summarisation tasks (via
#'   [da_submit()]).
#' * **Fetch** — if `data` already contains a `.task_id` column (i.e. it was
#'   previously returned by `llm_summarize()`), the function fetches results
#'   for any tasks that are still pending (via [da_fetch()]). In this case,
#'   all other parameters are ignored.
#'
#' Typical usage is to call `llm_summarize()` once to submit, and then call
#' it repeatedly on the returned data frame until all results are in (see
#' [da_finished()]).
#'
#' To customize the prompts, provide them in the options:
#'
#' ```
#' options = list(
#'   prompts = list(
#'     system = "YOURSYSTEMPROMPT",
#'     user = "YOURUSERPROMPT"
#'   )
#' )
#' ```
#'
#' If the prompts are given as character vectors, their elements are collapsed
#' using a line break (as in [llm_prompt()]).
#'
#' If present in the prompts, the placeholder `{{text}}` is replaced by the value of the current case.
#' The placeholder `{{rules}}` is replaced by a rule book generated from the rules data frame.
#'
#' See the databoard documentation for further options.
#'
#' @param data A data frame containing the texts to be summarised, or a data
#'   frame previously returned by `llm_summarize()` whose pending results
#'   should be fetched.
#' @param col A column in `data` holding the input text. Tidy-evaluation is
#'   supported (pass the bare column name).
#' @param rules Optional. Provide rules to produce multiple summaries.
#'   A data frame with the columns `category`, `description`, and `example`.
#'   One output is created for each category. The description should prompt
#'   what to summarize. Optionally, add an example of the expected output.
#' @param options A named list of additional options passed to the Databoard
#'   server.
#' @param wait Integer. Seconds to wait server-side per case for the task to
#'   complete before returning.
#'   * `0` (default): submit all tasks and return immediately with state
#'     `PENDING`. Fetch results later by calling `llm_summarize(data)` again.
#'   * `> 0`: wait up to that many seconds per case for the result.
#'
#' @return The input data frame with the columns `.task_id` and `.task_state`
#'   added. When results are available, they are unnested into additional
#'   result columns (e.g. `llm_result`).
#'
#' @seealso [llm_prompt()], [llm_code()], [da_submit()], [da_fetch()]]
#'
#' @examples
#' \dontrun{
#' # Log in to the Databoard service (requires valid credentials)
#' da_login()
#'
#' # Submit summarisation tasks
#' data <- llm_summarize(songs, text)
#'
#' # Fetch results: call the same function again with the returned
#' # data frame as the only argument. Repeat until all results are in.
#' data <- llm_summarize(data)
#'
#' # Inspect the summaries
#' head(data$llm_result)
#' }
#'
#' @export
llm_summarize <- function(data, col, rules, options = list(), wait = 0) {

  if (".task_id" %in% colnames(data)) {
    return (da_fetch(data))
  }

  if (!missing(rules)) {
    options$rules <- purrr::transpose(rules)
    options$mode <- "multi"
  } else {
    options$mode <- "single"
  }

  if (!is.null(options$prompts$system)) {
    options$prompts$system <- paste0(options$prompts$system, collapse = "\n")
  }
  if (!is.null(options$prompts$user)) {
    options$prompts$user <- paste0(options$prompts$user, collapse = "\n")
  }

  da_submit(data, {{ col }}, "summarize", options, wait)

}

#' Automated annotation with an LLM
#'
#' Submits each row of `data` to the Databoard `annotate` task, which asks an
#' LLM to annotate the text in `col` using `rules`. The server post-processes
#' the answer and returns tabular output columns.
#'
#' The function has two modes of operation, dispatched automatically:
#'
#' * **Submit** - if `data` does *not* yet contain a `.task_id` column, the
#'   texts in `col` are submitted as new annotation tasks (via [da_submit()]).
#' * **Fetch** - if `data` already contains a `.task_id` column (i.e. it was
#'   previously returned by `llm_annotate()`), the function fetches results for
#'   any tasks that are still pending (via [da_fetch()]). In this case,
#'   all other parameters are ignored.
#'
#' To customize prompts, pass `options$prompts$system` and/or
#' `options$prompts$user`.
#'
#' @param data A data frame containing the texts to be annotated, or a data
#'   frame previously returned by `llm_annotate()` whose pending results should be
#'   fetched.
#' @param col A column in `data` holding the input text. Tidy-evaluation is
#'   supported (pass the bare column name).
#' @param rules Required in submit mode. A data frame that is converted to an
#'   array of dicts with keys `category`, `description`, and `example`.
#'   The `description` is used to identify text segments. The `example` should
#'   contain comma-separated text segments that match the rule. The `category`
#'   is used as the `value` attribute in the annotation output.
#' @param options A named list of additional options passed to the Databoard
#'   server. See the databoad server documentation for available options.
#' @param wait Integer. Seconds to wait server-side per case for the task to
#'   complete before returning.
#'   * `0` (default): submit all tasks and return immediately with state
#'     `PENDING`. Fetch results later by calling `llm_annotate(data)` again.
#'   * `> 0`: wait up to that many seconds per case for the result.
#' @return The input data frame with the columns `.task_id` and `.task_state`
#'   added. When results are available, they are unnested into additional
#'   result columns (e.g. `llm_result`). For annotation tasks, `llm_annos`
#'   is added as a list-column with one data frame per case containing
#'   `value` and `segment`.
#'
#' @seealso [llm_prompt()], [llm_code()], [llm_summarize()], [da_submit()], [da_fetch()]
#'
#' @examples
#' \dontrun{
#' anno_rules <- tibble::tribble(
#'   ~category, ~description, ~example,
#'   "PERSON", "Names of people", "John Doe, Jane Roe",
#'   "PLACE", "Names of places", "Berlin, New York"
#' )
#'
#' # Submit
#' results <- llm_annotate(movies, abstract, anno_rules)
#'
#' # Fetch pending tasks
#' results <- llm_annotate(results)
#'
#' # Inspect annotations
#' head(results$llm_result)
#' results$llm_annos[[1]]
#' }
#'
#' @export
llm_annotate <- function(data, col, rules, options = list(), wait = 0) {

  if (".task_id" %in% colnames(data)) {
    return (da_fetch(data))
  }

  if (missing(rules) || is.null(rules)) {
    stop("Error: rules are required in submit mode.", call. = FALSE)
  }

  required_cols <- c("category", "description", "example")
  if (!is.data.frame(rules) || !all(required_cols %in% colnames(rules))) {
    stop("Error: rules must be a data frame with columns: category, description, example.", call. = FALSE)
  }

  options$rules <- purrr::transpose(rules[required_cols])

  if (!is.null(options$prompts$system)) {
    options$prompts$system <- paste0(options$prompts$system, collapse = "\n")
  }
  if (!is.null(options$prompts$user)) {
    options$prompts$user <- paste0(options$prompts$user, collapse = "\n")
  }

  da_submit(data, {{ col }}, "annotate", options, wait)

}

