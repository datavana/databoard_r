#' Extract annotation spans from llm_result
#'
#' Internal helper used by `llm_annotate()`: parses `<anno value="...">...</anno>`
#' tags and returns a tibble with `value` and `segment`.
#'
#' @param text Character scalar containing annotated text.
#' @return A tibble with columns `value` and `segment`.
#' @keywords internal
anno_extract <- function(text, tagname = "anno", attrname = "value") {

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

  nodes <- xml2::xml_find_all(doc, paste0(".//", tagname))
  if (length(nodes) == 0L) {
    return(empty)
  }

  tibble::tibble(
    value = xml2::xml_attr(nodes, attrname, default = ""),
    segment = xml2::xml_text(nodes, trim = TRUE)
  )
}

#' Inject character offsets into selected XML elements
#'
#' Walks the XML tree once in document order, accumulating a running character
#' offset over all text and CDATA nodes, and stamps `data-start` and `data-end`
#' attributes onto every selected element. Offsets are 1-based and inclusive,
#' and refer to positions in the *plain* (tag-stripped) text, i.e.
#' `xml2::xml_text(xml2::xml_root(doc))`.
#'
#' Elements are selected via `tagname` and/or `attrname`:
#' \itemize{
#'   \item only `tagname`: all elements with one of these names,
#'   \item only `attrname`: all elements carrying this attribute
#'     (default `"id"`),
#'   \item both: elements matching the name *and* carrying the attribute.
#' }
#'
#' The input is wrapped in a synthetic `<root>` element so that XML fragments
#' with multiple top-level nodes can be parsed; this wrapper is never stamped.
#' Consequently, the input must not contain an XML declaration or DOCTYPE.
#' Mixed content is handled correctly: a parent element's span covers both its
#' text runs and its child elements, while children span only their own
#' content. Comment and processing-instruction nodes are skipped, consistent
#' with how [xml2::xml_text()] treats them.
#'
#' Empty elements (e.g. `<anno value="x"></anno>`) get `data-end` equal to
#' `data-start - 1`, i.e. a zero-width span.
#'
#' @keywords internal
#'
#' @param xml Character value containing XML text. May be a fragment with
#'   several top-level nodes.
#' @param tagname Character vector of element names to stamp, or `NULL`.
#' @param attrname Name of an attribute; elements carrying it are stamped.
#'   Defaults to `"id"` if `tagname` is `NULL`, otherwise to `NULL`.
#' @return An `xml2::xml_document` with `data-start` and `data-end`
#'   integer-valued attributes injected onto all selected elements.
#' @seealso [anno_ranges()]
anno_offsets <- function(
  xml,
  tagname  = NULL,
  attrname = if (is.null(tagname)) "id" else NULL
) {
  if (is.null(tagname) && is.null(attrname)) {
    stop("At least one of `tagname` or `attrname` must be given.", call. = FALSE)
  }

  doc    <- xml2::read_xml(paste0("<root>", xml, "</root>"))
  offset <- 0L

  is_target <- function(node) {
    (is.null(tagname)  || xml2::xml_name(node) %in% tagname) &&
      (is.null(attrname) || xml2::xml_has_attr(node, attrname))
  }

  walk <- function(node, is_root = FALSE) {
    start <- offset + 1L                    # 1-based inclusive
    kids  <- xml2::xml_contents(node)
    types <- xml2::xml_type(kids)

    for (i in seq_along(kids)) {
      tp <- types[i]
      if (tp == "text" || tp == "cdata") {
        offset <<- offset + nchar(xml2::xml_text(kids[[i]]), type = "chars")
      } else if (tp == "element") {
        walk(kids[[i]])
      }
    }

    # only stamp nodes we care about, never the synthetic wrapper
    if (!is_root && is_target(node)) {
      xml2::xml_set_attr(node, "data-start", start)
      xml2::xml_set_attr(node, "data-end",   offset)
    }
  }

  walk(xml2::xml_root(doc), is_root = TRUE)
  doc
}


#' Extract segment text and character offsets
#'
#' Pulls both the plain text and the character-offset ranges for all elements
#' stamped by [anno_offsets()]. Works vectorized over the selected node
#' set, so repeated extraction from the same annotated document is cheap.
#'
#' Multiple matches (e.g. discontinuous annotations sharing an `id`, or several
#' segments with the same code) yield multiple spans, returned in document
#' order so that `segments` and `offsets` align element-for-element.
#'
#' @keywords internal
#'
#' @param doc One of: an `xml2::xml_document` already processed by
#'   [anno_offsets()]; a character value containing raw XML, which is
#'   annotated on the fly using `tagname` / `attrname`; or `NULL` / `NA`, in
#'   which case `NA` values are returned. Pass a pre-annotated document when
#'   extracting several values from the same content, to avoid re-parsing.
#' @param tagid Optional character vector of values of `attrname` (`id` by
#'   default) to keep. If `NULL`, all offset-annotated elements are returned.
#' @param tagname,attrname Element selection, see [anno_offsets()]. Used
#'   for annotating character input; `attrname` also determines the `value`
#'   column and what `tagid` is matched against.
#' @return A list with elements:
#'   \describe{
#'     \item{segments}{Text pieces joined by `;`.}
#'     \item{offsets}{Ranges as `"start-end"` joined by `;` (1-based,
#'       inclusive).}
#'     \item{length}{Character length of the full plain text.}
#'     \item{coverage}{Share of the plain text covered by the union of all
#'       segments.}
#'     \item{ranges}{A one-element list holding a data frame with columns
#'       `id`, `tag`, `value`, `start`, `end`, `text`, `length` (one row per
#'       matching element). `start`/`end` can be passed directly to
#'       `IRanges::IRanges()`.}
#'   }
#' @seealso [anno_offsets()], [covered_length()]
anno_ranges <- function(
  doc,
  tagid    = NULL,
  tagname  = NULL,
  attrname = if (is.null(tagname)) "id" else NULL
) {

  if (is.null(doc) || (is.character(doc) && (length(doc) == 0 || is.na(doc)))) {
    return(list(
      segments = NA_character_,
      offsets  = NA_character_,
      length   = NA_integer_,
      coverage = NA_real_,
      ranges   = list(NULL)
    ))
  }

  if (is.character(doc)) {
    doc <- anno_offsets(doc, tagname = tagname, attrname = attrname)
  }

  full_length <- nchar(xml2::xml_text(xml2::xml_root(doc)), type = "chars")

  els <- xml2::xml_find_all(doc, "//*[@data-start]")

  # Filter by tag id
  key <- if (is.null(attrname)) "id" else attrname
  if (!is.null(tagid)) {
    els <- els[xml2::xml_attr(els, key) %in% tagid]
  }

  pos <- data.frame(
    id     = xml2::xml_attr(els, "id"),
    tag    = xml2::xml_name(els),
    value  = if (is.null(attrname))
      rep(NA_character_, length(els))
      else xml2::xml_attr(els, attrname),
    start  = as.integer(xml2::xml_attr(els, "data-start")),
    end    = as.integer(xml2::xml_attr(els, "data-end")),
    text   = xml2::xml_text(els),
    length = rep(full_length, length(els)),
    stringsAsFactors = FALSE
  )

  if (nrow(pos) == 0) {
    return(list(
      segments = NA_character_,
      offsets  = NA_character_,
      length   = full_length,
      coverage = 0,
      ranges   = list(pos)
    ))
  }

  covered  <- covered_length(pos$start, pos$end)
  coverage <- if (full_length > 0) covered / full_length else NA_real_

  list(
    segments = paste0(pos$text, collapse = ";"),
    offsets  = paste0(pos$start, "-", pos$end, collapse = ";"),
    length   = full_length,
    coverage = coverage,
    ranges   = list(pos)
  )
}
