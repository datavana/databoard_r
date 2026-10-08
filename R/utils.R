#' Parse JSON from a response
#'
#' Only try to parse JSON if the server actually returned JSON.
#' For example, on HTTP errors the body may be an HTML error page.
#'
#' @param resp The server response as returned by [tasks_run_post()] or
#'   [tasks_run_get()].
#' @return The parsed JSON object or NULL
#'
#' @keywords internal
parse_json <- function(resp) {
    body <- NULL
  if (httr2::resp_has_body(resp) &&
      grepl("json", httr2::resp_content_type(resp), fixed = TRUE)) {
    body <- tryCatch(
      httr2::resp_body_json(resp, simplifyVector = TRUE),
      error = function(e) NULL
    )
  }

  body
}

#' Format time elapsed since a start time
#'
#' @param start POSIXct. Start time.
#' @return A string such as `"1m 05s"` or `"42s"`.
#' @keywords internal
#' @noRd
format_elapsed <- function(start) {
  secs <- round(as.numeric(difftime(Sys.time(), start, units = "secs")))
  if (secs < 60) {
    sprintf("%ds", secs)
  } else {
    sprintf("%dm %02ds", secs %/% 60, secs %% 60)
  }
}


#' Total length covered by a set of ranges
#'
#' Computes the number of positions covered by the *union* of 1-based,
#' inclusive integer ranges, so overlapping or nested ranges are counted only
#' once. Zero-width ranges (`end < start`, e.g. from empty elements) and ranges
#' containing `NA` are ignored.
#'
#' Equivalent to `sum(IRanges::width(IRanges::reduce(IRanges::IRanges(start,
#' end))))`, but without the Bioconductor dependency.
#'
#' @keywords internal
#'
#' @param start,end Integer vectors of equal length with range boundaries
#'   (1-based, inclusive).
#' @return A single integer: the number of covered positions.
#' @seealso [anno_ranges()]
covered_length <- function(start, end) {
  stopifnot(length(start) == length(end))

  ok <- !is.na(start) & !is.na(end) & end >= start
  if (!any(ok)) return(0L)

  start <- as.integer(start[ok])
  end   <- as.integer(end[ok])
  o     <- order(start, end)
  start <- start[o]
  end   <- end[o]

  total <- 0L
  cur_s <- start[1]
  cur_e <- end[1]
  for (i in seq_along(start)[-1]) {
    # overlapping or adjacent: merge
    if (start[i] <= cur_e + 1L) {
      cur_e <- max(cur_e, end[i])
    } else {
      total <- total + (cur_e - cur_s + 1L)
      cur_s <- start[i]
      cur_e <- end[i]
    }
  }
  total + (cur_e - cur_s + 1L)
}
