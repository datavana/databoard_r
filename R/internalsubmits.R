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
#'
#' @export
.submit_task <- function(data, col, task, rules = NULL, verbose = FALSE) {

  if (!is.logical(verbose) || length(verbose) != 1) {
    stop("`verbose` must be TRUE or FALSE.", call. = FALSE)
  }

  # ---- Access token ----
  access_token <- Sys.getenv("DATABOARD_ACCESS_TOKEN")
  if (access_token == "") {
    stop(
      "Error: No valid access token. ",
      "Please use the function \"db_login\" to generate an access token.",
      call. = FALSE
    )
  }

  # ---- Tidy evaluation ----
  col_quo  <- rlang::enquo(col)
  col_name <- rlang::as_name(col_quo)

  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }

  if (!col_name %in% names(data)) {
    stop(sprintf("Column '%s' not found in `data`.", col_name), call. = FALSE)
  }

  inputs <- as.character(data[[col_name]])
  n <- length(inputs)

  if (n == 0) {
    stop("Selected column contains no rows.", call. = FALSE)
  }

  # ---- Progress bar ----
  pb <- progress::progress_bar$new(
    format = "Submitting tasks [:bar] :current/:total (:percent)",
    total  = n,
    clear  = FALSE,
    width  = 60
  )

  # ---- Initialize output column ----
  data$db_id <- character(n)

  # ---- Main loop ----
  for (i in seq_len(n)) {
    # Prepare rules in the correct format for the API
    rules_for_api <- NULL
    if (!is.null(rules) && task == "coding") {
      # Convert named list to array format that matches Python structure
      rules_array <- lapply(names(rules), function(name) {
        rule <- rules[[name]]
        list(
          category = name,
          description = rule$description %||% "",
          example = rule$example %||% ""
        )
      })

      # The API expects rules wrapped in options object
      rules_for_api <- list(
        rules = rules_array,
        mode = "multi"  # or "single" - adjust as needed
      )

      if (verbose) {
        cat("\n=== Rules for row", i, "===\n")
        print(jsonlite::toJSON(rules_for_api, pretty = TRUE, auto_unbox = TRUE))
      }
    }

    req <- .build_task_request(
      input        = inputs[i],
      access_token = access_token,
      task         = task,
      rules        = rules_for_api,  # Pass the properly formatted rules
      verbose      = verbose
    )

    data$db_id[i] <- .execute_task_request(req,
                                           row_index = i,
                                           verbose = verbose)
    pb$tick()


  }

  # ---- Convert to tibble and save with new name ----
  # Convert to tibble (tidyverse data frame)
  data <- tibble::as_tibble(data)

  # Store task metadata as attributes for later use
  attr(data, "db_task") <- task
  attr(data, "db_rules") <- rules

  invisible(data)
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
#' @export
.get_taskresult <- function(data, id_col = db_id, task = NULL, rules = NULL) {

  # ---- Try to get task and rules from attributes if not provided ----
  if (is.null(task)) {
    task <- attr(data, "db_task")
    if (is.null(task)) {
      stop("Task type not provided and not found in data attributes. Please specify 'task' parameter.", call. = FALSE)
    }
    message(sprintf("Using task type '%s' from stored attributes", task))
  }

  if (is.null(rules)) {
    rules <- attr(data, "db_rules")
    if (!is.null(rules)) {
      message("Using rules from stored attributes")
    }
  }

  # ---- Access token ----
  access_token <- Sys.getenv("DATABOARD_ACCESS_TOKEN")
  if (access_token == "") {
    stop(
      "Error: No valid access token. ",
      "Please use the function \"db_login\" to generate an access token.",
      call. = FALSE
    )
  }

  # ---- Tidy evaluation ----
  id_col_quo  <- rlang::enquo(id_col)
  id_col_name <- rlang::as_name(id_col_quo)

  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }

  if (!id_col_name %in% names(data)) {
    stop(sprintf("Column '%s' not found in `data`.", id_col_name), call. = FALSE)
  }

  task_ids <- as.character(data[[id_col_name]])
  n <- length(task_ids)

  if (n == 0) {
    stop("Selected ID column contains no rows.", call. = FALSE)
  }

  # ---- Progress bar ----
  pb <- progress::progress_bar$new(
    format = "Retrieving results [:bar] :current/:total (:percent)",
    total  = n,
    clear  = FALSE,
    width  = 60
  )

  # ---- Retrieve results ----
  # Store results in order - they will match the task_ids by position
  results_list <- vector("list", n)

  for (i in seq_len(n)) {
    task_id <- task_ids[i]

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
        Sys.sleep(5)
      } else {
        result <- task_result$result$answers
      }
    }

    # Store result at position i - matches task_ids[i]
    results_list[[i]] <- result
    pb$tick()
  }

  # ---- Process results based on task type ----
  if (task == "summarize") {
    # Add summary column - extract from data frame structure
    data$db_summary <- vapply(results_list, function(x) {
      if (is.null(x) || length(x) == 0) return(NA_character_)
      # Check if it's a data frame with llm_result column
      if (is.data.frame(x) && "llm_result" %in% names(x)) {
        return(as.character(x$llm_result[1]))
      }
      # Handle list structure
      if (is.list(x) && !is.null(x$llm_result)) {
        return(as.character(x$llm_result))
      }
      if (is.list(x)) {
        return(as.character(x[[1]]))
      }
      return(as.character(x[1]))
    }, FUN.VALUE = character(1))

  } else if (task == "coding") {
    # Extract category names from rules
    if (is.null(rules)) {
      warning("No rules provided for coding task. Cannot extract category-specific results.", call. = FALSE)
      # Store the raw results as list column
      data$db_result <- I(results_list)
    } else {
      categories <- names(rules)

      if (is.null(categories) || length(categories) == 0) {
        warning("Rules has no named categories. Storing raw results.", call. = FALSE)
        data$db_result <- I(results_list)
      } else {
        message(sprintf("\nExtracting %d categories from results: %s",
                        length(categories), paste(categories, collapse = ", ")))

        # The API returns llm_result_<category> fields
        for (cat in categories) {
          col_name <- paste0("db_", cat)
          api_field_name <- paste0("llm_result_", cat)

          message(sprintf("Creating column '%s' from field '%s'", col_name, api_field_name))

          data[[col_name]] <- vapply(results_list, function(x) {
            if (is.null(x)) return(NA_character_)

            # Check if it's a list with the expected field
            if (is.list(x) && !is.null(x[[api_field_name]])) {
              result_value <- as.character(x[[api_field_name]])
              # Return the value, convert "None" or empty to NA
              if (is.na(result_value) || result_value == "" || result_value == "None") {
                return(NA_character_)
              }
              return(result_value)
            }

            # If field not found
            return(NA_character_)
          }, FUN.VALUE = character(1))
        }
      }
    }

  } else {
    # For other task types (annotate, triples), create list column with db_ prefix
    data$db_result <- I(results_list)
  }

  # ---- Convert to tibble and save with original name ----
  data <- tibble::as_tibble(data)
  invisible(data)
}
