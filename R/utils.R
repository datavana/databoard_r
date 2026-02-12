#' Build a Databoard task request
#'
#' Constructs an \code{httr2} request object for submitting a task to the
#' Databoard API. This function does not perform the request.
#'
#' @param input A character string containing the task input text.
#' @param access_token A character string containing the Databoard API
#'   access token. Should be already saved in the system environment.
#' @param task Task for the llm to perform. Can be either coding or summary.
#'
#' @param rules Rules for the coding process. Need to follow in a specific format,
#'              e.g. Category: Description.
#' @return An \code{httr2_request} object ready to be executed.
#'
#' @details
#' Prompt fields are only included when explicitly supplied, allowing
#' the API to apply its default behavior otherwise.
#'
#' @keywords internal
.build_task_request <- function(input,
                                access_token,
                                task,
                                rules = NULL,
                                verbose = FALSE) {
  if (!is.logical(verbose) || length(verbose) != 1) {
    stop("`verbose` must be TRUE or FALSE.", call. = FALSE)
  }

  body <- list(
    task  = task,
    input = list(input)  # CHANGED: wrap in list()
  )

  if (!is.null(rules)) {
    body$options <- rules  # CHANGED: rules goes into options, not directly in body
  }

  httr2::request("https://databoard.uni-muenster.de/tasks/run") |>
    httr2::req_auth_bearer_token(access_token) |>
    httr2::req_body_json(body)
}

#' Execute a Databoard task request
#'
#' Performs an \code{httr2} request, validates the HTTP response, and
#' extracts the task identifier.
#'
#' @param req An \code{httr2_request} object created by
#'   \code{.build_task_request()}.
#' @param row_index Optional integer indicating the row number associated
#'   with the request. Used for informative error messages.
#'
#' @return A character string containing the task ID.
#'
#' @details
#' The function errors if the HTTP status code indicates failure or if
#' the response does not contain a \code{task_id} field.
#'
#' @keywords internal
.execute_task_request <- function(req, row_index = NULL, verbose = FALSE) {

  if (!is.logical(verbose) || length(verbose) != 1) {
    stop("`verbose` must be TRUE or FALSE.", call. = FALSE)
  }

  if (verbose) {
    message("Executing task request for row ", row_index)
    message(req$body)
  }

  resp <- httr2::req_perform(req)
  status <- httr2::resp_status(resp)

  if (status < 200 || status >= 300) {
    stop(
      sprintf(
        "Task submission failed%s (HTTP %d).",
        if (!is.null(row_index)) paste0(" at row ", row_index) else "",
        status
      ),
      call. = FALSE
    )
  }

  body <- httr2::resp_body_json(resp, simplifyVector = TRUE)

  if (is.null(body$task_id)) {
    stop("API response did not contain a task_id.", call. = FALSE)
  }

  body$task_id
}
