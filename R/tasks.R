#
# Wrappers for specific tasks
#


#' Automated content coding with an LLM
#'
#' Submits each row of `data` to the Databoard `coding` task, which asks an
#' LLM to assign category codes to the text in `col` based on a set of coding
#' `rules`. Thin wrapper around [da_submit()].
#'
#' @param data A data frame containing the texts to be coded.
#' @param col A column in `data` holding the input text. Tidy-evaluation is
#'   supported (pass the bare column name).
#' @param rules A data frame describing the coding scheme, with the columns
#'   `category`, `description`, and `example`. One row per category.
#' @param mode Character. Coding mode:
#'   * `"single"` — return the single best-matching category per case.
#'   * `"multi"` (default) — return a value per category, where
#'     `0` = does not apply, `1` = applies, `2` = fully applies.
#' @param options A named list of additional options passed to the Databoard
#'   server. `rules` and `mode` are added automatically.
#' @param wait Integer. Seconds to wait server-side per case for the task to
#'   complete before returning.
#'   * `0` (default): submit all tasks and return immediately with state
#'     `PENDING`. Fetch results later via [da_fetch()].
#'   * `> 0`: wait up to that many seconds per case for the result.
#'
#'   In either case, [da_fetch()] can be called later to complete any tasks
#'   that are still pending.
#'
#' @return The input data frame with the columns `.task_id` and `.task_state`
#'   added. When results are already available, they are unnested into
#'   additional result columns.
#'
#' @seealso [da_submit()], [da_fetch()], [llm_summarize()]
#'
#' @export
llm_code <- function(data, col, rules = NULL, mode = "multi", options = list(), wait = 0) {

  options$rules <- purrr::transpose(rules)
  options$mode <- mode
  da_submit(data, {{ col }}, "coding", options, wait)

}

#' Automated content summarisation with an LLM
#'
#' Submits each row of `data` to the Databoard `summarize` task, which asks
#' an LLM to summarise the text in `col`. Optionally, a `rules` data frame
#' can be provided to produce structured, per-category summaries. Thin
#' wrapper around [da_submit()].
#'
#' @param data A data frame containing the texts to be summarised.
#' @param col A column in `data` holding the input text. Tidy-evaluation is
#'   supported (pass the bare column name).
#' @param rules Optional. A data frame describing the summary structure, with
#'   the columns `category`, `description`, and `example`. Required for
#'   `mode = "multi"`, ignored otherwise.
#' @param mode Character. Summary mode:
#'   * `"single"` (default) — produce a single free-text summary per case.
#'   * `"multi"` — produce one summary per category defined in `rules`.
#' @param options A named list of additional options passed to the Databoard
#'   server. `rules` (if given) and `mode` are added automatically.
#' @param wait Integer. Seconds to wait server-side per case for the task to
#'   complete before returning.
#'   * `0` (default): submit all tasks and return immediately with state
#'     `PENDING`. Fetch results later via [da_fetch()].
#'   * `> 0`: wait up to that many seconds per case for the result.
#'
#'   In either case, [da_fetch()] can be called later to complete any tasks
#'   that are still pending.
#'
#' @return The input data frame with the columns `.task_id` and `.task_state`
#'   added. When results are already available, they are unnested into
#'   additional result columns.
#'
#' @seealso [da_submit()], [da_fetch()], [llm_code()]
#'
#' @export
llm_summarize <- function(data, col, rules, mode = "single", options = list(), wait = 0) {

  if (!missing(rules)) {
    options$rules <- purrr::transpose(rules)
  }
  options$mode <- mode
  da_submit(data, {{ col }}, "summarize", options, wait)

}
