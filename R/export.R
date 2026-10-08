#' Export annotated texts as a REFI-QDA project
#'
#' Converts a data frame whose text column contains inline XML annotations
#' (e.g. `Finde <anno value="B2 Aufwerten">Ich super so</anno>!`) into a
#' REFI-QDA project file (`.qdpx`). The file can be imported into MAXQDA,
#' ATLAS.ti, NVivo, QDA Miner and other REFI-compliant software.
#'
#' Each row becomes one text source. The annotation tags are stripped, and
#' each annotated element becomes a coded segment. Its code is taken from the
#' attribute `code_attr`. Codes are created in order of first appearance. With
#' `code_sep`, code names are split into a hierarchy, e.g.
#' `"B Bewertung::B2 Aufwerten"` with `code_sep = "::"` creates the subcode
#' `B2 Aufwerten` below `B Bewertung`.
#'
#' Properly nested annotations are supported. Overlapping (non-nested) tags
#' are not well-formed XML and cannot be represented. Texts must be
#' well-formed XML fragments, so literal `&` and `<` must be escaped as
#' `&amp;` and `&lt;`. Empty annotations and annotations without
#' `code_attr` are skipped with a warning.
#'
#' Internally, offsets are computed by [anno_offsets()] (1-based,
#' inclusive) and converted to REFI positions (0-based, end exclusive,
#' counted in characters).
#'
#' @param df A data frame.
#' @param file Path of the `.qdpx` file to write. Overwritten if it exists.
#' @param text_col Name of the column containing the annotated texts. `NA`
#'   values become empty sources.
#' @param name_col Optional name of a column with document names. If `NULL`,
#'   documents are named `"Document 001"`, `"Document 002"`, and so on.
#'   Duplicate names are made unique.
#' @param project_name Name of the project.
#' @param user_name Name of the user recorded as creator of all objects.
#' @param tagname Character vector of annotation element names.
#' @param code_attr Name of the attribute holding the code name.
#' @param code_sep Optional separator for hierarchical code names, e.g.
#'   `"::"`. If `NULL`, all codes are top-level codes.
#' @return The normalized path of the written file, invisibly.
#' @seealso [anno_offsets()], [anno_ranges()]
#' @export
#'
#' @examples
#' df <- data.frame(
#'   id   = c("Interview_01", "Interview_02"),
#'   text = c(
#'     paste('Finde <anno value="B2 Aufwerten">Ich super so</anno>!',
#'           'Die autogerechte Stadt ist auf jeden Fall vorbei.'),
#'     paste('Mehr <anno value="A1 Verkehr">Radwege',
#'           '<anno value="B2 Aufwerten">w\u00e4ren sch\u00f6n</anno></anno>.')
#'   ),
#'   stringsAsFactors = FALSE
#' )
#' out <- as_refi(df, file.path(tempdir(), "projekt.qdpx"), name_col = "id")
#' file.exists(out)
as_refi <- function(
  df,
  file         = "project.qdpx",
  text_col     = "llm_result",
  name_col     = NULL,
  project_name = "Databoard export",
  user_name    = "Databoard",
  tagname      = "anno",
  code_attr    = "value",
  code_sep     = "::"
) {

  # --- checks ---------------------------------------------------------------
  if (!is.data.frame(df)) {
    stop("`df` must be a data frame.", call. = FALSE)
  }
  if (!text_col %in% names(df)) {
    stop("Column '", text_col, "' not found in `df`.", call. = FALSE)
  }
  if (!is.null(name_col) && !name_col %in% names(df)) {
    stop("Column '", name_col, "' not found in `df`.", call. = FALSE)
  }

  now <- refi_timestamp()

  # --- document names -------------------------------------------------------
  default_names <- sprintf("Document %03d", seq_len(nrow(df)))
  doc_names <- if (is.null(name_col)) default_names
  else as.character(df[[name_col]])
  missing_name <- is.na(doc_names) | !nzchar(trimws(doc_names))
  doc_names[missing_name] <- default_names[missing_name]
  doc_names <- make.unique(doc_names, sep = "_")

  # --- parse all texts ------------------------------------------------------
  parsed <- lapply(seq_len(nrow(df)), function(i) {
    refi_codings(
      df[[text_col]][i],
      tagname   = tagname,
      code_attr = code_attr,
      label     = paste0("Row ", i, " (", doc_names[i], ")")
    )
  })

  # --- temp dir -------------------------------------------------------------
  tmp <- tempfile("refi_")
  dir.create(file.path(tmp, "Sources"), recursive = TRUE)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)

  # --- XML skeleton ---------------------------------------------------------
  user_guid <- refi_guid()
  doc <- xml2::xml_new_root(
    "Project",
    name             = project_name,
    origin           = "R as_refi",
    creatingUserGUID = user_guid,
    creationDateTime = now,
    xmlns            = "urn:QDA-XML:project:1.0"
  )
  users <- xml2::xml_add_child(doc, "Users")
  xml2::xml_add_child(users, "User", guid = user_guid, name = user_name)
  codebook     <- xml2::xml_add_child(doc, "CodeBook")
  codes_node   <- xml2::xml_add_child(codebook, "Codes")
  sources_node <- xml2::xml_add_child(doc, "Sources")

  # --- codebook -------------------------------------------------------------
  all_codes  <- unique(unlist(lapply(parsed, function(p) p$codings$code)))
  code_guids <- refi_codebook(codes_node, all_codes, code_sep = code_sep)

  # --- sources + codings ----------------------------------------------------
  for (i in seq_along(parsed)) {

    p      <- parsed[[i]]
    s_guid <- refi_guid()
    fname  <- paste0(s_guid, ".txt")
    writeBin(charToRaw(enc2utf8(p$text)), file.path(tmp, "Sources", fname))

    src <- xml2::xml_add_child(
      sources_node, "TextSource",
      guid             = s_guid,
      name             = doc_names[i],
      plainTextPath    = paste0("internal://", fname),
      creatingUser     = user_guid,
      creationDateTime = now
    )

    cds <- p$codings
    for (j in seq_len(nrow(cds))) {

      seg_txt <- substr(p$text, cds$start[j], cds$end[j])

      sel <- xml2::xml_add_child(
        src, "PlainTextSelection",
        guid             = refi_guid(),
        name             = substr(seg_txt, 1, 60),
        startPosition    = cds$start[j] - 1L, # 0-based
        endPosition      = cds$end[j],        # exclusive
        creatingUser     = user_guid,
        creationDateTime = now
      )

      cod <- xml2::xml_add_child(
        sel, "Coding",
        guid             = refi_guid(),
        creatingUser     = user_guid,
        creationDateTime = now
      )

      xml2::xml_add_child(
        cod, "CodeRef",
        targetGUID = unname(code_guids[cds$code[j]])
      )
    }
  }

  xml2::write_xml(doc, file.path(tmp, "project.qde"), encoding = "UTF-8")

  # --- zip to .qdpx ---------------------------------------------------------
  file <- normalizePath(file, mustWork = FALSE)
  if (file.exists(file)) file.remove(file)
  zip::zip(file, files = c("project.qde", "Sources"), root = tmp)

  invisible(file)
}


#' Parse one annotated text for REFI export
#'
#' Annotates a single XML fragment with [anno_offsets()], extracts the
#' coded segments with [anno_ranges()], and returns the plain text
#' together with the codings. Elements with a missing or empty code and empty
#' (zero-width) elements are dropped with a warning.
#'
#' @keywords internal
#'
#' @param x A single character value with inline XML annotations, or `NA`
#'   (treated as an empty text).
#' @param tagname Character vector of annotation element names.
#' @param code_attr Name of the attribute holding the code name.
#' @param label Optional label (e.g. row and document name) used to prefix
#'   error and warning messages.
#' @return A list with elements `text` (plain text, character) and `codings`
#'   (data frame with columns `code`, `start`, `end`; 1-based, inclusive).
#' @seealso [as_refi()]
refi_codings <- function(
    x, tagname = "anno", code_attr = "value",
    label = NULL
  ) {

  prefix <- if (is.null(label)) "" else paste0(label, ": ")
  x <- if (length(x) == 0 || is.na(x)) "" else enc2utf8(as.character(x))

  d <- tryCatch(
    anno_offsets(x, tagname = tagname, attrname = code_attr),
    error = function(e) {
      stop(prefix, "invalid XML - ", conditionMessage(e), call. = FALSE)
    }
  )

  seg <- anno_ranges(d, tagname = tagname, attrname = code_attr)$ranges[[1]]

  code <- trimws(seg$value)
  no_code <- is.na(code) | !nzchar(code)
  empty   <- seg$end < seg$start

  if (any(no_code)) {
    warning(
      prefix, sum(no_code), " annotation(s) without '", code_attr,
      "' skipped.", call. = FALSE
    )
  }
  if (any(empty & !no_code)) {
    warning(
      prefix, sum(empty & !no_code), " empty annotation(s) skipped.",
      call. = FALSE
    )
  }

  keep <- !no_code & !empty
  list(
    text    = xml2::xml_text(xml2::xml_root(d)),
    codings = data.frame(
      code  = code[keep],
      start = seg$start[keep],
      end   = seg$end[keep],
      stringsAsFactors = FALSE
    )
  )
}


#' Build a (hierarchical) REFI codebook
#'
#' Adds `<Code>` elements for the given code names to a `<Codes>` node. If
#' `code_sep` is given, code names are split into hierarchy levels and parent
#' codes are created as needed. Each parent is created once, even if it is
#' shared by several subcodes.
#'
#' @keywords internal
#'
#' @param codes_node An `xml2` node (the `<Codes>` element of the project).
#' @param codes Character vector of unique code names.
#' @param code_sep Optional separator for hierarchical code names.
#' @return A named character vector mapping each element of `codes` to the
#'   GUID of its (leaf) `<Code>` element.
#' @seealso [as_refi()]
refi_codebook <- function(codes_node, codes, code_sep = NULL) {
  path_guid <- character(0)   # hierarchy path -> GUID
  path_node <- list()         # hierarchy path -> xml node
  leaf_guid <- character(0)   # original code name -> leaf GUID

  for (cd in codes) {
    parts <- if (is.null(code_sep)) cd
    else trimws(strsplit(cd, code_sep, fixed = TRUE)[[1]])
    parts <- parts[nzchar(parts)]
    if (length(parts) == 0) {
      stop("Invalid code name: '", cd, "'.", call. = FALSE)
    }

    parent <- codes_node
    for (k in seq_along(parts)) {
      key <- paste(parts[seq_len(k)], collapse = "\u001f")
      if (!key %in% names(path_guid)) {
        g <- refi_guid()
        path_node[[key]] <- xml2::xml_add_child(parent, "Code",
                                                guid      = g,
                                                name      = parts[k],
                                                isCodable = "true")
        path_guid[key] <- g
      }
      parent <- path_node[[key]]
    }
    leaf_guid[cd] <- path_guid[key]
  }

  leaf_guid
}


#' Generate a GUID for REFI-QDA objects
#'
#' @keywords internal
#' @return A single upper-case UUID string.
refi_guid <- function() {
  toupper(uuid::UUIDgenerate())
}


#' Current time as REFI-QDA timestamp
#'
#' @keywords internal
#' @return A single character value in ISO 8601 format (UTC), e.g.
#'   `"2024-05-01T12:00:00Z"`.
refi_timestamp <- function() {
  format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
}
