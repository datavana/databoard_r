#' Login-Function for the Databoard API
#'
#' This function logs into the [Databoard-API](https://databoard.uni-muenster.de/) and returns a valid access token. Please contact the [Digital Media and Computational Methods](https://www.uni-muenster.de/Kowi/en/personen/jakob-juenger.shtml) research unit to acquire an user account. Please make sure to keep your login data and access token private.
#'
#' @param username Username for the Login
#' @param pw Password for the Login
#'
#' @return The access Token saved within the system environment
#' @export
db_login <- function(username, pw) {
  basepath <- "https://databoard.uni-muenster.de"
  path <- "/token"
  body <- list(username = username, password = pw)

  res <- httr::POST(paste0(basepath, path), body = body, encode = "form")

  if (httr::status_code(res) == 200) {
    access_token <- httr::content(res, as = "parsed", type = "application/json")$access_token
    settings <- list(DATABOARD_ACCESS_TOKEN = access_token)
    do.call(Sys.setenv, settings)
    message("Logged in, access token saved in system environment")
    return(invisible(TRUE))
  } else {
    warning("Password or Username wrong", call. = FALSE)
    return(invisible(FALSE))
  }
}

#' Automated content summaries with llms
#'
#' This function uses the databoard service from the
#' [Digital Media and Computational Methods](https://www.uni-muenster.de/Kowi/en/personen/jakob-juenger.shtml)
#' research unit to facilitate automated summaries with llms.
#'
#' @param data Your dataframe with text to be coded.
#' @param col The column in which the text to be coded is stored.
#' @returns Your original dataframe with additional columns with the coded results.
#' @export
llm_summarize <- function(data, col) {
  # Capture original name
  original_name <- deparse(substitute(data))
  new_name <- paste0("db_", original_name)

  # Submit tasks
  col_enquo <- rlang::enquo(col)

  submitted_data <- .submit_task(data = data, col = !!col_enquo, task = "summarize")

  # Get results
  result <- .get_taskresult(submitted_data)

  # Save only the final result with correct name
  .GlobalEnv[[new_name]] <- result

  # Clean up intermediate objects
  if (exists("submitted_data", envir = .GlobalEnv)) {
    rm("submitted_data", envir = .GlobalEnv)
  }
  if (exists("db_data", envir = .GlobalEnv)) {
    rm("db_data", envir = .GlobalEnv)
  }

  # Return invisibly
  invisible(result)
}

#' Automated content coding with llms
#'
#' This function uses the databoard service from the
#' [Digital Media and Computational Methods](https://www.uni-muenster.de/Kowi/en/personen/jakob-juenger.shtml)
#' research unit to facilitate automated summaries with llms.
#'
#' @param data Your dataframe with text to be coded.
#' @param col The column in which the text to be coded is stored.
#' @param rules The rules for your coding.
#' @returns Your original dataframe with additional columns with the coded results.
#' @export
llm_code <- function(data, col, rules) {
  # Capture original name
  original_name <- deparse(substitute(data))
  new_name <- paste0("db_", original_name)

  # Submit tasks
  col_enquo <- rlang::enquo(col)

  submitted_data <- .submit_task(data = data, col = !!col_enquo, task = "coding", rules = rules)

  # Get results
  result <- .get_taskresult(submitted_data)

  # Save only the final result with correct name
  .GlobalEnv[[new_name]] <- result

  # Clean up intermediate objects
  if (exists("submitted_data", envir = .GlobalEnv)) {
    rm("submitted_data", envir = .GlobalEnv)
  }
  if (exists("db_data", envir = .GlobalEnv)) {
    rm("db_data", envir = .GlobalEnv)
  }

  # Return invisibly
  invisible(result)
}
