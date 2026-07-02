#
# Wrappers for specific tasks
#


#' Automated content coding with an LLM
#'
#' Submits each row of `data` to the Databoard `coding` task, which asks an
#' LLM to assign category codes to the text in `col` based on a set of coding
#' `rules`.
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
#'   server.
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
#' @seealso [llm_summarize()], [da_submit()], [da_fetch()], [da_finished()]
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
  da_submit(data, {{ col }}, "coding", options, wait)

}

#' Automated content summarisation with an LLM
#'
#' Submits each row of `data` to the Databoard `summarize` task, which asks
#' an LLM to summarise the text in `col`. Optionally, a `rules` data frame
#' can be provided to produce structured, per-category summaries.
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
#' @seealso [llm_code()], [da_submit()], [da_fetch()], [da_finished()]
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

  da_submit(data, {{ col }}, "summarize", options, wait)

}
