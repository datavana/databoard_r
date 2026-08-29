#
# Databoard interaction
#


#' Login to the Databoard service
#'
#' Authenticates against the Databoard-API and stores the returned access token
#' in the system environment for subsequent calls. Please contact the Digital
#' Media and Computational Methods research unit to acquire a user account.
#' Keep your login data and access token private.
#'
#' @param username Character. Username for the login. If missing, the user is
#'   prompted interactively.
#' @param password Character. Password for the login. If missing, the user is
#'   prompted interactively with a masked prompt (via the `askpass` package
#'   if available, otherwise an unmasked `readline()` fallback).
#' @param server Character. Base URL of the Databoard server. Defaults to
#'   `https://databoard.uni-muenster.de/`.
#' @param verbose Logical. If `TRUE`, subsequent API calls will print
#'   additional diagnostic information. Stored in the environment variable
#'   `DATABOARD_VERBOSE`.
#' @param silent Logical. If `TRUE`, failing API calls will not stop processing further tasks.
#'    Stored in the environment variable `DATABOARD_SILENT`.
#' @return Invisibly returns `TRUE` on successful login and `FALSE` otherwise.
#'   As a side effect, sets the environment variables `DATABOARD_SERVER`,
#'   `DATABOARD_ACCESSTOKEN`, and `DATABOARD_VERBOSE`.
#'
#' @export
da_login <- function(username, password, server = getOption("databoard.baseurl", DATABOARD_BASEURL), verbose = FALSE, silent = TRUE) {

  if (missing(username)) {
    if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
      username <- rstudioapi::showPrompt(
        title   = "Databoard login",
        message = "Please, enter your user name:",
        default = ""
      )
    } else {
      username <- readline(prompt = "Please, enter your user name: ")
    }
  }

  if (missing(password)) {
    if (requireNamespace("askpass", quietly = TRUE)) {
      password <- askpass::askpass("Please, enter your password: ")
    } else {
      warning(
        "Package 'askpass' is not installed; password input will not be masked. ",
        "Install it with install.packages(\"askpass\") for a secure prompt.",
        call. = FALSE
      )
      password <- readline(prompt = "Please, enter your password: ")
    }
  }

  if (is.null(username) || is.null(password) || !nzchar(username) || !nzchar(password)) {
    message("Login cancelled.")
    return(invisible(FALSE))
  }

  body     <- list(username = username, password = password)
  endpoint <- paste0(server, "/token")
  res      <- httr::POST(endpoint, body = body, encode = "form")

  if (httr::status_code(res) == 200) {

    accesstoken <- httr::content(res, as = "parsed", type = "application/json")$access_token

    settings <- list(
      DATABOARD_SERVER      = server,
      DATABOARD_ACCESSTOKEN = accesstoken,
      DATABOARD_VERBOSE     = verbose,
      DATABOARD_SILENT      = silent
    )
    do.call(Sys.setenv, settings)

    message("Logged in, access token saved in system environment.")

    return(invisible(TRUE))
  } else {
    warning("Invalid username or password.", call. = FALSE)
    return(invisible(FALSE))
  }
}

#' Log out from the Databoard service
#'
#' Clears the environment variables set by [da_login()]
#' (`DATABOARD_SERVER`, `DATABOARD_ACCESSTOKEN`, `DATABOARD_VERBOSE`, and `DATABOARD_SILENT`),
#' effectively ending the current session. Subsequent API calls will fail
#' until [da_login()] is called again.
#'
#' @return Invisibly returns `TRUE`.
#'
#' @seealso [da_login()]
#'
#' @export
da_logout <- function() {

  Sys.unsetenv(c(
    "DATABOARD_SERVER",
    "DATABOARD_ACCESSTOKEN",
    "DATABOARD_VERBOSE",
    "DATABOARD_SILENT"
  ))

  message("Logged out, access token cleared from system environment.")

  invisible(TRUE)
}

#' Submit tasks to the Databoard service
#'
#' Submits one Databoard task per row of `data`, using the values of `col` as
#' input. Task metadata (id, state) and results are stored back into `data` in
#' the special columns `.task_id`, `.task_state`, and `.task_result`. After
#' submission, results are unnested into regular columns and a progress
#' summary is printed.
#'
#' @param data A data frame containing the input data.
#' @param col A column in `data` holding the text input. Tidy-evaluation is
#'   supported (i.e. pass the bare column name).
#' @param task Character. The task the LLM is supposed to perform (e.g.
#'   `"summarize"`, `"coding"`, `"annotate"`, `"triples"`).
#' @param options A named list of task-specific options passed to the API
#'   (e.g. coding rules, model parameters).
#' @param wait Integer. Seconds to wait server-side for immediate completion of
#'   each task before returning. `0` (default) returns immediately with a
#'   `PENDING` state; larger values reduce the need for later `da_fetch()`
#'   calls.
#'
#' @return The input data frame with additional columns:
#'   `.task_id`, `.task_state`, and one column per field returned by the task
#'   (unnested from `.task_result`).
#'
#' @details Tasks are submitted sequentially, one per row. The function stops
#'   immediately if a submission fails.
#'
#' @export
da_submit <- function(data, col, task, options, wait = 0) {

  input <- dplyr::pull(data, {{ col }})

  # Progress bar
  n <- length(input)
  pb <- progress::progress_bar$new(
    format = "Submitting tasks [:bar] :current/:total (:percent)",
    total  = n, clear  = FALSE, width  = 60, show_after = 0,
  )
  pb$tick(0)

  # Main loop
  for (i in seq_len(n)) {
    resp <- tasks_run_post(task, input[i], options, wait)
    data <- da_extract(data, resp, i)
    pb$tick()
    if (!check_authorized(resp)) {
      break
    }
  }

  data <- da_unnest(data)
  da_progress(data, TRUE)

  data
}

#' Fetch results for previously submitted tasks
#'
#' Iterates over rows of `data` and retrieves results for any task that is
#' still in the `PENDING` state. Newly received results overwrite the
#' corresponding rows' `.task_state` and `.task_result` values, and are
#' unnested into regular columns.
#'
#' @param data A data frame previously produced by [da_submit()]. Must contain
#'   a `.task_id` column.
#' @param wait Integer. Seconds to wait server-side per request for the task
#'   to complete before returning. Defaults to `10`.
#'
#' @return The input data frame with updated `.task_state` values and unnested
#'   result columns.
#'
#' @export
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
    total  = n, clear  = FALSE, width  = 60, show_after = 0,
  )
  pb$tick(0)

  # Main loop
  for (i in seq_len(n)) {

    if (data$.task_state[i] == "PENDING") {
      resp <- tasks_run_get(data$.task_id[i], wait)
      data <- da_extract(data, resp, i)
      if (!check_authorized(resp)) {
        break
      }
    }
    pb$tick()

  }

  data <- da_unnest(data)
  da_progress(data, TRUE)

  data
}

#' Extract task metadata and result into a data frame row
#'
#' Internal helper that writes the fields of an API response `body` into row
#' `no` of `data`. Creates the columns `.task_id`, `.task_state`, and
#' `.task_result` on the fly if they don't yet exist.
#'
#' @param data A data frame to be updated.
#' @param resp The server response as returned by [tasks_run_post()] or
#'   [tasks_run_get()].
#' @param no Integer. Row index in `data` to write to.
#'
#' @return The updated data frame.
#'
#' @keywords internal
da_extract <- function(data, resp, no) {

  if (!(".task_id" %in% colnames(data))) {
    data$.task_id <- NA
  }

  if (!(".task_state" %in% colnames(data))) {
    data$.task_state <- NA
  }

  if (!(".task_result" %in% colnames(data))) {
    data$.task_result <- NA
  }

  statuscode <- httr2::resp_status(resp)
  body <- parse_json(resp)

  # Task ID
  if (!is.null(body$task_id)) {
    data$.task_id[no] <- body$task_id
  }

  # Task state
  if (!is.null(body$state)) {
    data$.task_state[no] <- body$state
  } else {
    data$.task_state[no] <- paste0("CODE ", statuscode)
  }

  # Task answers
  answers <- body$result$answers
  if (is.null(answers) || length(answers) == 0L) {
    data$.task_result[no] <- list(tibble::tibble())
  } else {
    data$.task_result[no] <- list(tibble::as_tibble(answers))
  }

  # Task messages
  if (!is.null(body$msg)) {
    if (!(".task_msg" %in% colnames(data))) {
      data$.task_msg <- NA
    }
    data$.task_msg[no] <- body$msg
  }

  data
}

#' Unnest the `.task_result` list-column into regular columns
#'
#' Expands the tibble-valued `.task_result` column into one column per result
#' field. If the resulting columns already exist in `data`, only rows that
#' actually carry a task result (i.e. where `.task_result` is not `NA`) are
#' updated; other rows keep their existing values. The `.task_id` and
#' `.task_state` columns are moved to the end.
#'
#' @param data A data frame containing a `.task_result` list-column. If the
#'   column is absent, `data` is returned unchanged.
#'
#' @return The data frame with `.task_result` unnested into individual columns.
#'
#' @keywords internal
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

  if ("llm_result" %in% colnames(out)) {
    has_anno_tags <- any(!is.na(out$llm_result) & grepl("<anno\\b", out$llm_result, perl = TRUE))
    if (has_anno_tags) {
      out$llm_annos <- lapply(out$llm_result, extract_annos)
    }
  }

  dplyr::relocate(
    out,
    dplyr::any_of(c(".task_id", ".task_state", ".task_msg")),
    .after = dplyr::last_col()
  )
}

#' Summarise task states of a Databoard data frame
#'
#' Returns (and optionally prints) a summary of how many tasks are in each
#' state (e.g. `PENDING`, `SUCCESS`, `FAILURE`). The formatted message shows
#' the percentage per state on a single line, with colour coding.
#'
#' @param data A data frame containing a `.task_state` column (as produced by
#'   [da_submit()] / [da_fetch()]).
#' @param message Logical. If `TRUE`, prints a nicely formatted, colourised
#'   one-line summary via [cli::cli_inform()] and returns the counts
#'   invisibly. If `FALSE` (default), just returns the counts.
#'
#' @return A named list with `TOTAL` (the total number of rows) and one entry
#'   per observed task state.
#'
#' @export
da_progress <- function(data, message = FALSE) {

  if (!(".task_state" %in% colnames(data))) {
    stop("Error: The data frame does not contain any task states.", call. = FALSE)
  }

  data$.task_state[is.na(data$.task_state)] <- "UNDEFINED"

  total        <- nrow(data)
  state_counts <- as.list(table(data[[".task_state"]], useNA = "ifany"))
  result       <- c(list(TOTAL = total), state_counts)

  if (message) {

    parts <- vapply(names(state_counts), function(state) {
      n       <- state_counts[[state]]
      pct     <- if (total > 0) n / total * 100 else 0
      label   <- if (is.na(state) || is.null(state)) "NA" else state
      colorfn <- STATE_COLORS[[label]] %||% cli::col_black
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

#' Check whether all tasks have finished
#'
#' Returns `TRUE` if no task in `data` is still in the `PENDING` state.
#'
#' @param data A data frame containing a `.task_state` column.
#'
#' @return Logical scalar. `TRUE` if all tasks have left the `PENDING` state,
#'   `FALSE` otherwise.
#'
#' @export
da_finished <- function(data) {

  if (!(".task_state" %in% colnames(data))) {
    stop("Error: The data frame does not contain any task states.", call. = FALSE)
  }

  all(data$.task_state != "PENDING")
}

#' Send a request to the databoard server
#'
#' @param endpoint The path including a leading slash
#' @param body If provided, the body is send via a POST request.
#'            Otherwise, a GET request is issued.
#' @param wait Seconds to wait for an answer. Set to 0 to return immediately.
#' @return The response object.
da_request <- function(endpoint, body, wait = 0) {

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

  req <- httr2::request(paste0(server, endpoint)) |>
    httr2::req_auth_bearer_token(accesstoken) |>
    httr2::req_url_query(wait = wait)

  if (!missing(body)) {
    req <- httr2::req_body_json(req, body)
  }

  # Don't stop at HTTP errors, retry after rate limits
  req <- req |>
    httr2::req_retry(max_tries = getOption("databoard.maxretries", DATABOARD_MAXRETRIES)) |>
    httr2::req_error(is_error = function(resp) FALSE)

  resp <- httr2::req_perform(req)
  check_succesful(resp)
  resp

}

#' Submit a single task to the Databoard API (low level)
#'
#' Sends one `POST /tasks/run` request to the Databoard API. This is the
#' underlying request helper used by [da_submit()]; end users typically don't
#' need to call it directly.
#'
#' @param task Character. The task type (e.g. `"summarize"`, `"coding"`,
#'   `"annotate"`, `"triples"`).
#' @param input Character. The input text for the task. Must be non-empty.
#' @param options A named list of task-specific options passed to the API.
#' @param wait Integer. Seconds to wait server-side for the task to complete
#'   before returning. Defaults to `0`.
#'
#' @return The server response
#'
#' @details Requires prior authentication via [da_login()]; the access token
#'   is read from the `DATABOARD_ACCESSTOKEN` environment variable. Stops with
#'   an informative error if the token is missing or the HTTP status is not
#'   2xx.
#'
#' @keywords internal
tasks_run_post <- function(task, input, options, wait = 0) {

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

  da_request(endpoint, body, wait = wait)
}


#' Retrieve a single task result from the Databoard API (low level)
#'
#' Sends one `GET /tasks/run/{task_id}` request to the Databoard API. This is
#' the underlying request helper used by [da_fetch()]; end users typically
#' don't need to call it directly.
#'
#' @param task_id Character. The identifier of a previously submitted task.
#' @param wait Integer. Seconds to wait server-side for the task to complete
#'   before returning. Defaults to `0`.
#'
#' @return The server response.
#'
#' @details Requires prior authentication via [da_login()]; the access token
#'   is read from the `DATABOARD_ACCESSTOKEN` environment variable. Stops with
#'   an informative error if the token is missing or the HTTP status is not
#'   2xx.
#'
#' @keywords internal
tasks_run_get <- function(task_id, wait = 0) {


  if (missing(task_id)) {
    stop("Error: empty task ID.", call. = FALSE)
  }

  endpoint <- paste0("/tasks/run/", task_id)
  da_request(endpoint, wait = wait)
}


#' Check whether a response contains status code 401
#'
#' Stops with an error message if DATABOARD_SILENT is not TRUE.
#'
#' @param resp The server response as returned by [tasks_run_post()] or
#'   [tasks_run_get()].
#' @return A boolean indicating whether the user is authorized.
#'
#' @seealso [da_login()]
#'
#' @keywords internal
check_authorized <- function(resp) {
  authorized <- httr2::resp_status(resp) != 401
  silent <- Sys.getenv("DATABOARD_SILENT") == "TRUE"

  if (!authorized & !silent) {
    stop(
      sprintf("Error: Task submission failed (status code %d).", status),
      call. = FALSE
    )
  }

  authorized
}

#' Check whether a response was successful (code 20x)
#'
#' Stops with an error message if DATABOARD_SILENT is not TRUE.
#'
#'
#' @param resp The server response as returned by [tasks_run_post()] or
#'   [tasks_run_get()].
#' @return A boolean indicating whether the response was succesful
#'
#' @keywords internal
check_succesful <- function(resp) {

  status <- httr2::resp_status(resp)
  successful = ! ((status < 200 || status >= 300))

  silent <- Sys.getenv("DATABOARD_SILENT") == "TRUE"
  if (!silent & !successful) {

    msg <- "Error: Processing request failed (status code %d)."

    # Get message if available
    body <- parse_json(resp)
    if (!is.null(body$msg)) {
      msg <- paste0(msg, " ", body$msg)
    }

    stop(
      sprintf(msg, status),
      call. = FALSE
    )
  }

  successful
}
