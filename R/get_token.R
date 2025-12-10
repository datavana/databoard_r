#' Login-Function for the Databoard API
#'
#' This function logs into the [Databoard-API](https://databoard.uni-muenster.de/) and returns a valid access token. Please contact the [Digital Media and Computational Methods](https://www.uni-muenster.de/Kowi/en/personen/jakob-juenger.shtml) research unit to acquire an user account. Please make sure to keep your login data and access token private.
#'
#' @param username Username for the Login
#' @param pw Password for the Login
#'
#' @return The access Token saved within the system environment
#' @export

get_token <- function(username, pw) {
  url <- "https://databoard.uni-muenster.de/token"
  body <- list(username = username, password = pw)

  res <- httr::POST(url, body = body, encode = "form")

  if (httr::status_code(res) == 200) {
    access_token <- httr::content(res, as = "parsed", type = "application/json")$access_token
    settings <- list(DATABOARD_ACCESS_TOKEN = access_token)
    do.call(Sys.setenv, settings)
    message("Logged in, access token saved in system environment")
    return(invisible(TRUE))
  } else {
    warning("Passwort oder Username falsch", call. = FALSE)
    return(invisible(FALSE))
  }
}


