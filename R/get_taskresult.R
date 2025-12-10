#' Get your task results
#'
#' @inheritParams
#'
#' @returns Your original dataframe with additional columns with the coded results.
#' @export
#'
#' @examples
#' input <- "This is a comment about love"
#' access_token <- "your personal access token"
#' system_prompt <- "Code when the word 'love' is mentioned"
#' submit_task(input, access_token, system_prompt)

get_taskresult <- function(task_id) {

  access_token <- Sys.getenv("DATABOARD_ACCESS_TOKEN")
  if (access_token == "") {
    stop("Error: No valid access token. Please use get_token() to generate an access token.")
  }

  task_state <- "PENDING"
  result <- NULL

  while (identical(task_state, "PENDING")) {
    resp <- httr2::request(
      paste0("https://databoard.uni-muenster.de/tasks/run/", task_id)
    ) |>
      httr2::req_auth_bearer_token(access_token) |>
      httr2::req_url_query(wait = 5) |>
      httr2::req_perform()

    task_result <- httr2::resp_body_json(resp, simplifyVector = TRUE)

    task_state <- dplyr::coalesce(task_result$state, "UNKNOWN")

    if (identical(task_state, "PENDING")) {
      cat("Waiting 5 more seconds…\n")
      Sys.sleep(5)
    } else {
      result <- task_result$result$answers
    }
  }

  cat(sprintf("\n Task %s finished with state %s\n", task_id, task_state))
  return(result)
}
