#
# Databoard interaction
#


#' Login to the databoard service
#'
#' This function logs into the [Databoard-API](https://databoard.uni-muenster.de/) and returns a valid access token. Please contact the [Digital Media and Computational Methods](https://www.uni-muenster.de/Kowi/en/personen/jakob-juenger.shtml) research unit to acquire an user account. Please make sure to keep your login data and access token private.
#'
#' @param username Username for the Login
#' @param pw Password for the Login
#'
#' @return The access Token saved within the system environment
#' @export
da_login <- function(username, password, server = DATABOARD_BASEURL, verbose = FALSE) {

  if (missing(username)) {
    username <- readline(prompt="Please, enter your user name: ")
  }

  if (missing(password)) {
    password <- readline(prompt="Please, enter your password: ")
  }

  body <- list(username = username, password = password)
  endpoint <- paste0(server, "/token")
  res <- httr::POST(endpoint, body = body, encode = "form")

  if (httr::status_code(res) == 200) {

    accesstoken <- httr::content(res, as = "parsed", type = "application/json")$access_token

    settings <- list(
      DATABOARD_SERVER = server,
      DATABOARD_ACCESSTOKEN = accesstoken,
      DATABOARD_VERBOSE = verbose
    )
    do.call(Sys.setenv, settings)

    message("Logged in, access token saved in system environment.")

    return(invisible(TRUE))
  } else {
    warning("Invalid username or password.", call. = FALSE)
    return(invisible(FALSE))
  }
}

#' Automated content coding with llms
#'
#' @param data Your data frame with text to be coded.
#' @param col The column containing the input text.
#' @param rules The coding rules as a dataframe with the columns `category`, `description`, and `example`.
#' @param mode Set to `single` to get the matching category for each case.
#'             Set to `multi` to get a value for each category, where 0 = does not apply, 1 = applies, 2= fully applies.
#' @returns Your original dataframe with additional columns with the coded results.
da_submit <- function(data, col, task, options, wait = 0) {

  input <- dplyr::pull(data, {{ col }})

  # Progress bar
  n <- length(input)
  pb <- progress::progress_bar$new(
    format = "Submitting tasks [:bar] :current/:total (:percent)",
    total  = n, clear  = FALSE, width  = 60
  )

  # Main loop
  for (i in seq_len(n)) {
    body <- tasks_run_post(task, input[i], options, wait)
    data <- da_extract(data, body, i)
    pb$tick()
  }

  data <- da_unnest(data)
  da_progress(data, TRUE)

  data
}

da_fetch <- function(data, wait = 10) {

  # Prepare columns

  if (!(".task_id" %in% colnames(data))) {
    stop("Error: The data frame lacks a task id column. First, submit tasks. ", call. = FALSE)
  }

  if (!(".task_state" %in% colnames(data))) {
    data$.task_state <- NA
  }

  # Progress bar
  n <- nrow(data)
  pb <- progress::progress_bar$new(
    format = "Fetching task results [:bar] :current/:total (:percent)",
    total  = n, clear  = FALSE, width  = 60
  )

  # Main loop
  for (i in seq_len(n)) {

    if (data$.task_state[i] == "PENDING") {
      body <- tasks_run_get(data$.task_id[i], wait)
      data <- da_extract(data, body, i)
    }
    pb$tick()

  }

  data <- da_unnest(data)
  da_progress(data, TRUE)

  data
}

da_extract <- function(data, body, no) {


  if (!(".task_id" %in% colnames(data))) {
    data$.task_id <- NA
  }

  if (!(".task_state" %in% colnames(data))) {
    data$.task_state <- NA
  }

  if (!(".task_result" %in% colnames(data))) {
    data$.task_result <- NA
  }

  if (is.null(body$task_id)) {
    stop("Error: Response did not contain a valid task_id.", call. = FALSE)
  }

  data$.task_id[no] <- body$task_id
  data$.task_state[no] <- body$state

  answers <- body$result$answers
  if (is.null(answers) || length(answers) == 0L) {
    data$.task_result[no] <- list(tibble::tibble())
  } else {
    data$.task_result[no] <- list(tibble::as_tibble(answers))
  }

  data
}

da_unnest <- function(data) {

  if (!(".task_result" %in% colnames(data))) {
    return(data)
  }

  has <- !is.na(data[[".task_result"]])

  out <- tidyr::unnest(
    data, ".task_result",
    keep_empty = TRUE,
    names_sep = ".."
  )

  cols <- grep("^.task_result..", names(out), value = TRUE)
  bare     <- sub("^.task_result..", "", cols)

  for (i in seq_along(cols)) {
    col <- bare[i]
    if (col %in% names(out)) {
      out[[col]][has] <- out[[cols[i]]][has]
    } else {
      out[[col]] <- out[[cols[i]]]
    }
    out[[cols[i]]] <- NULL
  }

  dplyr::relocate(
    out,
    dplyr::any_of(c(".task_id", ".task_state")),
    .after = dplyr::last_col()
  )
}

da_progress <- function(data, message = FALSE) {

  if (!(".task_state" %in% colnames(data))) {
    stop("Error: The data frame does not contain any task states.", call. = FALSE)
  }

  result <- as.list(table(data[[".task_state"]]))

  total        <- nrow(data)
  state_counts <- as.list(table(data[[".task_state"]], useNA = "ifany"))
  result       <- c(list(TOTAL = total), state_counts)

  if (message) {

    # Colour palette for known states; fallback to white
    state_colors <- list(
      SUCCESS = cli::col_green,
      PENDING = cli::col_yellow,
      FAILURE = cli::col_red,
      RETRY   = cli::col_magenta,
      STARTED = cli::col_cyan,
      REVOKED = cli::col_silver
    )

    parts <- vapply(names(state_counts), function(state) {
      n       <- state_counts[[state]]
      pct     <- if (total > 0) n / total * 100 else 0
      label   <- if (is.na(state) || is.null(state)) "NA" else state
      colorfn <- state_colors[[label]] %||% cli::col_white
      colorfn(sprintf("%.0f%% %s", pct, label))
    }, character(1))

    msg <- paste0(
      cli::style_bold(sprintf("%d tasks: ", total)),
      paste(parts, collapse = " | ")
    )

    cli::cli_inform(msg)

    invisible(result)
  } else {
    result
  }
}

da_finished <- function(data) {

  if (!(".task_state" %in% colnames(data))) {
    stop("Error: The data frame does not contain any task states.", call. = FALSE)
  }

  all(data$.task_state != "PENDING")
}


#' Submit Databoard tasks for each row of a data frame
#'
#' Submits a task to the Databoard API for each row of a selected column
#' in a data frame and returns a new data frame with task IDs.
#'
#' @param data A data frame containing the input data.
#' @param col A column in \code{data} containing the text input.
#'   Tidy-evaluation is supported.
#' @param task The task the llm is supposed to perform. Can be either 'summarize', 'coding', 'annotate' or 'triples'.
#' @param rules Your specific coding rules in the following format: .
#' @param verbose Logical. If TRUE, prints detailed progress information.
#' @return A data frame identical to \code{data} with an additional
#'   \code{db_id} column containing the submitted task identifiers.
#'   The data frame is saved in the parent environment with the name "db_" + original name.
#' @details
#' Tasks are submitted sequentially, one per row. The function stops
#' immediately if a submission fails.
tasks_run_post <- function(task, input, options, wait = 0) {

  # Get server and token from the global settings
  server <- Sys.getenv("DATABOARD_SERVER")
  accesstoken <- Sys.getenv("DATABOARD_ACCESSTOKEN")
  verbose <- Sys.getenv("DATABOARD_VERBOSE") == "TRUE"

  # Access token
  if (accesstoken == "") {
    stop(
      "Error: No valid access token. ",
      "Please use the function \"da_login()\" to generate an access token.",
      call. = FALSE
    )
  }

  n <- length(input)
  if (n == 0) {
    stop("Error: empty input data.", call. = FALSE)
  }

  endpoint <- "/tasks/run"
  body <- list(
    task = task,
    input = input,
    options = options
  )

  res <- httr2::request(paste0(server, endpoint)) |>
    httr2::req_auth_bearer_token(accesstoken) |>
    httr2::req_url_query(wait = wait) |>
    httr2::req_body_json(body) |>
    httr2::req_perform()

  status <- httr2::resp_status(res)
  if (status < 200 || status >= 300) {
    stop(
      sprintf("Error: Task submission failed (status code %d).", status),
      call. = FALSE
    )
  }

  body <- httr2::resp_body_json(res, simplifyVector = TRUE)
  body
}


#' Get task results and merge with original data frame
#'
#' Retrieves results for all task IDs in a data frame and adds result columns.
#'
#' @param data A data frame containing task IDs (typically created by db_submit_task).
#' @param id_col The column containing task IDs. Default is "db_id".
#'   Tidy-evaluation is supported.
#' @param task The task type that was performed. Can be either 'summarize', 'coding', 'annotate' or 'triples'.
#' @param rules Your specific coding rules (needed to extract category names for coding tasks).
#' @return The original data frame with additional columns containing the results.
#'   For 'summarize' task: adds a 'db_summary' column.
#'   For 'coding' task: adds 'db_<category>' columns for each category in rules.
#'   The data frame is saved in the parent environment with its original name.
tasks_run_get <- function(task_id, wait = 0) {

  # Get server and token from the global settings
  server <- Sys.getenv("DATABOARD_SERVER")
  accesstoken <- Sys.getenv("DATABOARD_ACCESSTOKEN")
  verbose <- Sys.getenv("DATABOARD_VERBOSE") == "TRUE"

  # Access token
  if (accesstoken == "") {
    stop(
      "Error: No valid access token. ",
      "Please use the function \"da_login()\" to generate an access token.",
      call. = FALSE
    )
  }


  if (missing(task_id)) {
    stop("Error: empty task ID.", call. = FALSE)
  }

  endpoint <- "/tasks/run"

  res <- httr2::request(paste0(server, endpoint, "/", task_id)) |>
    httr2::req_auth_bearer_token(accesstoken) |>
    httr2::req_url_query(wait = wait) |>
    httr2::req_perform()

  status <- httr2::resp_status(res)
  if (status < 200 || status >= 300) {
    stop(
      sprintf("Error: Fetching task result failed (status code %d).", status),
      call. = FALSE
    )
  }

  body <- httr2::resp_body_json(res, simplifyVector = TRUE)
  body
}

