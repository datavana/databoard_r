#' Submit tasks to be automatically coded
#'
#' @inheritParams run_pipeline
#'
#' @returns Your original dataframe with additional columns with the coded results.
#' @export
#'
#' @examples
#' input <- "This is a comment about love"
#' system_prompt <- "Code when the word 'love' is mentioned"
#' submit_coding(input, system_prompt)
#' submit_summary(input, system_prompt)


submit_code <- function(input, rules, waittime = 5, temperature = 0) {

  access_token <- Sys.getenv("DATABOARD_ACCESS_TOKEN")
  if (access_token == "") {
    stop("Error: No valid access token. Please use the function get_token to generate an access token.")
  }
  resp <- httr2::request("https://databoard.uni-muenster.de/tasks/run") |>
    httr2::req_auth_bearer_token(access_token) |>
    httr2::req_url_query(wait = waittime) |>
    httr2::req_body_json(list(
      task   = "coding",
      input  = input,
      options = list(
        prompts = list(
          rules = rules,
          mode = "multi",
          user = "{{text}}"
        )
      )
    )) |>
    httr2::req_perform()
  if (httr2::resp_status(resp) >= 200 && httr2::resp_status(resp) < 300) {
    task_result <- httr2::resp_body_json(resp, simplifyVector = TRUE)
    task_id <- task_result$task_id
    cat(sprintf("Submitted task %s\n", task_id))
    return(task_id)
  } else {
    stop("Failed to submit task")
  }
}


submit_summary <- function(input, system_prompt, waittime = 5, temperature = 0) {

  access_token <- Sys.getenv("DATABOARD_ACCESS_TOKEN")
  if (access_token == "") {
    stop("Error: No valid access token. Please use the function get_token to generate an access token.")
  }
  resp <- httr2::request("https://databoard.uni-muenster.de/tasks/run") |>
    httr2::req_auth_bearer_token(access_token) |>
    httr2::req_url_query(wait = waittime) |>
    httr2::req_body_json(list(
      task   = "summarize",
      input  = input,
      options = list(
        prompts = list(
          system = system_prompt,
          user = "{{text}}"
        )
      )
    )) |>
    httr2::req_perform()
  if (httr2::resp_status(resp) >= 200 && httr2::resp_status(resp) < 300) {
    task_result <- httr2::resp_body_json(resp, simplifyVector = TRUE)
    task_id <- task_result$task_id
    cat(sprintf("Submitted task %s\n", task_id))
    return(task_id)
  } else {
    stop("Failed to submit task")
  }
}
