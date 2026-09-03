#' Extract annotation spans from llm_result
#'
#' Internal helper used by `llm_annotate()`: parses `<anno value="...">...</anno>`
#' tags and returns a tibble with `value` and `segment`.
#'
#' @param text Character scalar containing annotated text.
#' @return A tibble with columns `value` and `segment`.
#' @keywords internal
extract_annos <- function(text) {

  empty <- tibble::tibble(value = character(0), segment = character(0))

  if (is.null(text) || length(text) != 1L || is.na(text)) {
    return(empty)
  }

  text <- as.character(text)
  if (!nzchar(trimws(text))) {
    return(empty)
  }

  wrapped <- paste0("<root>", text, "</root>")
  doc <- tryCatch(xml2::read_html(wrapped), error = function(e) NULL)
  if (is.null(doc)) {
    return(empty)
  }

  nodes <- xml2::xml_find_all(doc, ".//anno")
  if (length(nodes) == 0L) {
    return(empty)
  }

  tibble::tibble(
    value = xml2::xml_attr(nodes, "value", default = ""),
    segment = xml2::xml_text(nodes, trim = TRUE)
  )
}


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
