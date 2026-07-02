#
# Wrappers for specific tasks
#


#' Automated content coding by LLMs
#'
#' @param data Your data frame with text to be coded.
#' @param col The column containing the input text.
#' @param rules The coding rules as a dataframe with the columns `category`, `description`, and `example`.
#' @param mode Set to `single` to get the matching category for each case.
#'             Set to `multi` to get a value for each category, where 0 = does not apply, 1 = applies, 2= fully applies.
#' @param options Additional parameters passed to the databoard server.
#' @param wait Seconds to wait for the results, for each case.
#'             Set to 0 to immediately submit all tasks. Get the results by calling da_fetch() on your data frame.
#'             Set to a number of seconds greater than 0 to wait for each cases result.
#'             In any case, you can later call `da_fetch()` to supplement result for non-finished tasks once they are ready.
#' @returns Your original data frame with the columns `.task_id` and `.task_state` added.
#'          If result are ready, those data is stored in additional columns prefixed with `llm_result_`.
#' @export
llm_code <- function(data, col, rules = NULL, mode = "multi", options = list(), wait = 0) {

  options$rules <- purrr::transpose(rules)
  options$mode <- mode
  da_submit(data, {{ col }}, "coding", options, wait)

}

#' Automated content summary by LLMs
#'
#' @param mode Set to `single` to output a single summary for each case.
#'             Set to `multi` to get a value for each category. In this case, you need to provide rules.
#' @export
llm_summarize <- function(data, col, rules, mode = "single", options = list(), wait = 0) {

  if (!missing(rules)) {
    options$rules <- purrr::transpose(rules)
  }
  options$mode <- mode
  da_submit(data, {{ col }}, "summarize", options, wait)

}
