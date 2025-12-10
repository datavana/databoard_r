#' Automated content coding with llms
#'
#' This function uses the databoard service from the [Digital Media and Computational Methods](https://www.uni-muenster.de/Kowi/en/personen/jakob-juenger.shtml) research unit to facilitate automated content coding with llms.
#'
#' @param input Text for coding, ideally a dataframe with an identifier (e.g. ID) and the text for coding.
#' @param access_token Your personal access token to the databoard service. For generating use the get_token function.
#' @param system_prompt The coding rules for your specific project. Should be in the form of a txt.file in the same folder. See [here](https://databoard.uni-muenster.de/) for examples.
#' @param temperature The desired temperature (e.g. the level of answer-randomness). Add numerical value, the default is set to 1.
#'
#' @returns Your original dataframe with additional columns with the coded results.
#' @export
#'
#' @examples
#' input <- "This is a comment about love"
#' access_token <- "your personal access token"
#' system_prompt <- "Code when the word 'love' is mentioned"
#' run_pipeline(input, access_token, system_prompt)


run_pipeline <- function(input, system_prompt, waittime = 5, temperature = 0) {

  # Validate access token
  access_token <- Sys.getenv("DATABOARD_ACCESS_TOKEN")
  if (access_token == "") {
    stop("Error: No valid access token. Please use get_token() to generate an access token.")
  }

  # Submit task and receive task ID
  task_id <- submit_task(
    input        = input,
    system_prompt = system_prompt,
    waittime     = waittime,
    temperature  = temperature
  )

  # Retrieve and return results
  result <- get_taskresult(task_id)
  return(result)
}

#Zusätzlich implementieren
# databoard  |>
#mutate(llm = map(text, ~ run_task_for_text(.x, access_token, system_prompt)))  |>
#  unnest(llm) |>
#  mutate(data = map(llm_result, fromJSON))  |>
#  unnest_wider(data) |>
#  select(-llm_result)
