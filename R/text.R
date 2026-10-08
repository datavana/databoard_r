#' Split a text column into overlapping chunks
#'
#' Splits the text in a data frame column into chunks of at most `maxsize`
#' characters, preferring natural boundaries. The text is first split at
#' blank lines (paragraphs). Pieces that are still too long are split at line
#' breaks, then at word breaks, and finally at character level. Small pieces
#' are then greedily merged back together up to `maxsize`. The trailing pieces
#' of each chunk are repeated at the start of the next chunk to create an
#' overlap of up to `overlap` characters.
#'
#' The chunk text replaces the content of `col` (the column name is kept), so
#' the result can be piped directly into functions that expect the original
#' column, e.g. `llm_annotate(text, rules)`. All other columns are carried
#' along unchanged.
#'
#' @param df A data frame or tibble.
#' @param col <[`data-masking`][rlang::args_data_masking]> The text column to
#'   chunk, given unquoted (tidyverse style). Must be a character column.
#' @param maxsize Maximum chunk size in characters. A single positive number.
#' @param overlap Target overlap in characters between consecutive chunks of
#'   the same text. Must be non-negative and smaller than `maxsize`. Overlap
#'   is built from whole pieces (paragraphs, lines, words), so the actual
#'   overlap is *up to* `overlap` characters. Only the character-level
#'   fallback produces an exact overlap.
#' @param separators Character vector of regular expressions, tried in order
#'   from coarsest to finest. The default splits at blank lines, then line
#'   breaks, then whitespace between words. A character-level fallback is
#'   always appended automatically.
#'
#' @return A tibble with one row per chunk. It contains all columns of `df`,
#'   with `col` holding the chunk text and two additional columns placed
#'   directly after `col`:
#'   \describe{
#'     \item{`chunk`}{Running chunk number within each original row (integer).}
#'     \item{`chunk_size`}{Number of characters in the chunk (integer).}
#'   }
#'   Rows where `col` is `NA` or empty are kept, with `NA` text and
#'   `chunk_size`.
#'
#' @details Chunks are trimmed of leading and trailing whitespace, so
#'   `chunk_size` refers to the trimmed text. Sizes are measured in
#'   characters, not tokens. As a rough rule of thumb, one token is about
#'   4 characters for English text.
#'
#' @examples
#' df <- tibble::tibble(
#'   doc  = c("a", "b"),
#'   text = c(
#'     "First paragraph.\n\nSecond paragraph,\nwith two lines.\n\nThird.",
#'     "Averyveryverylongwordwithoutanyspacesthatmustbecut"
#'   )
#' )
#'
#' chunk_text(df, text, maxsize = 30, overlap = 10)
#'
#' # Add sentence boundaries between line and word breaks
#' chunk_text(
#'   df, text, maxsize = 30, overlap = 10,
#'   separators = c("\n\\s*\n", "\n", "(?<=[.!?])\\s+", "[ \t]+")
#' )
#'
#' @export
chunk_text <- function(
  df, col,
  maxsize = 1000,
  overlap = 100,
  separators = c("\n\\s*\n", "\n", "[ \t]+")
) {
  # ---- input validation ----------------------------------------------------
  if (!is.data.frame(df)) {
    rlang::abort("`df` must be a data frame.")
  }
  col_name <- rlang::as_name(rlang::enquo(col))
  if (!col_name %in% names(df)) {
    rlang::abort(paste0("Column `", col_name, "` not found in `df`."))
  }
  if (!is.character(df[[col_name]])) {
    rlang::abort(paste0("Column `", col_name, "` must be a character column."))
  }
  if (!is.numeric(maxsize) || length(maxsize) != 1 || is.na(maxsize) || maxsize < 1) {
    rlang::abort("`maxsize` must be a single positive number.")
  }
  if (!is.numeric(overlap) || length(overlap) != 1 || is.na(overlap) ||
      overlap < 0 || overlap >= maxsize) {
    rlang::abort("`overlap` must be a single number >= 0 and < `maxsize`.")
  }
  if (!is.character(separators)) {
    rlang::abort("`separators` must be a character vector of regular expressions.")
  }

  maxsize    <- as.integer(maxsize)
  overlap    <- as.integer(overlap)
  separators <- unique(c(separators, ""))  # "" = character-level fallback

  # temporary id column; make sure it does not clash with existing columns
  id_col <- ".chunk_row_id"
  while (id_col %in% names(df)) id_col <- paste0(".", id_col)

  # ---- chunking ------------------------------------------------------------
  df |>
    dplyr::mutate(
      !!id_col := dplyr::row_number(),
      {{ col }} := purrr::map(
        {{ col }},
        \(x) split_text(x, maxsize, overlap, separators)
      )
    ) |>
    tidyr::unnest_longer({{ col }}, keep_empty = TRUE) |>
    dplyr::mutate(
      chunk      = dplyr::row_number(),
      chunk_size = stringr::str_length({{ col }}),
      .by        = dplyr::all_of(id_col),
      .after     = {{ col }}
    ) |>
    dplyr::select(-dplyr::all_of(id_col)) |>
    tibble::as_tibble()
}


#' Split a single text into trimmed chunks
#'
#' Wrapper around [split_recursive()] that handles missing or empty input and
#' trims the resulting chunks.
#'
#' @param x A single character string.
#' @param maxsize Maximum chunk size in characters.
#' @param overlap Target overlap in characters.
#' @param separators Character vector of regexes, ending with `""`.
#'
#' @return A character vector of non-empty, trimmed chunks. Returns
#'   `character(0)` if `x` is `NA` or contains only whitespace.
#'
#' @keywords internal
split_text <- function(x, maxsize, overlap, separators) {
  if (is.na(x) || stringr::str_trim(x) == "") {
    return(character(0))
  }
  chunks <- split_recursive(x, maxsize, overlap, separators) |>
    stringr::str_trim()
  chunks[chunks != ""]
}


#' Recursively split text using a hierarchy of separators
#'
#' Splits `x` at the first separator in `separators` that occurs in the
#' text. Pieces that fit into `maxsize` are collected and merged with
#' [merge_pieces()]. Pieces that are still too long are split recursively
#' with the remaining, finer separators. The empty separator `""` triggers
#' a hard character-level split via [hard_split()].
#'
#' @param x A single character string.
#' @param maxsize Maximum chunk size in characters.
#' @param overlap Target overlap in characters.
#' @param separators Character vector of regexes, ordered from coarsest to
#'   finest, ending with `""`.
#'
#' @return A character vector of chunks, each at most `maxsize` characters.
#'
#' @keywords internal
split_recursive <- function(x, maxsize, overlap, separators) {
  if (stringr::str_length(x) <= maxsize) {
    return(x)
  }

  # first separator that actually occurs in x ("" always matches)
  idx  <- purrr::detect_index(separators, \(s) s == "" || stringr::str_detect(x, s))
  sep  <- separators[idx]
  rest <- separators[-seq_len(idx)]

  if (sep == "") {
    return(hard_split(x, maxsize, overlap))
  }

  out    <- character()
  buffer <- character()
  for (p in split_keep(x, sep)) {
    if (stringr::str_length(p) <= maxsize) {
      buffer <- c(buffer, p)
    } else {
      # flush collected small pieces, then recurse into the oversized one
      out    <- c(out, merge_pieces(buffer, maxsize, overlap))
      buffer <- character()
      out    <- c(out, split_recursive(p, maxsize, overlap, rest))
    }
  }
  c(out, merge_pieces(buffer, maxsize, overlap))
}


#' Split a string at a regex, keeping the separators
#'
#' Splits `x` at every match of `sep` and attaches each separator to the
#' preceding piece. Pasting the pieces back together reproduces the original
#' text exactly.
#'
#' @param x A single character string.
#' @param sep A regular expression (non-empty).
#'
#' @return A character vector of non-empty pieces. Returns `x` unchanged if
#'   `sep` does not occur in it.
#'
#' @keywords internal
split_keep <- function(x, sep) {
  locs <- stringr::str_locate_all(x, sep)[[1]]
  if (nrow(locs) == 0) {
    return(x)
  }
  starts <- c(1L, locs[, "end"] + 1L)
  ends   <- c(locs[, "end"], stringr::str_length(x))
  pieces <- stringr::str_sub(x, starts, ends)
  pieces[pieces != ""]
}


#' Hard split a string at character level
#'
#' Cuts `x` into windows of `maxsize` characters, each starting
#' `maxsize - overlap` characters after the previous one. This produces an
#' exact overlap of `overlap` characters. Trailing windows that would only
#' repeat the overlap are dropped.
#'
#' @param x A single character string.
#' @param maxsize Maximum chunk size in characters.
#' @param overlap Exact overlap in characters (must be `< maxsize`).
#'
#' @return A character vector of chunks, each at most `maxsize` characters.
#'
#' @keywords internal
hard_split <- function(x, maxsize, overlap) {
  n      <- stringr::str_length(x)
  starts <- seq(1L, n, by = maxsize - overlap)
  starts <- starts[starts == 1L | starts + overlap <= n]
  stringr::str_sub(x, starts, pmin(starts + maxsize - 1L, n))
}


#' Greedily merge pieces into overlapping chunks
#'
#' Concatenates consecutive pieces until adding the next one would exceed
#' `maxsize`. The chunk is then emitted, and pieces are dropped from its
#' front until at most `overlap` characters remain and the next piece fits.
#' The remaining pieces become the start (overlap) of the next chunk.
#'
#' @param pieces Character vector of pieces, each at most `maxsize`
#'   characters.
#' @param maxsize Maximum chunk size in characters.
#' @param overlap Target overlap in characters.
#'
#' @return A character vector of chunks, each at most `maxsize` characters.
#'   Returns `character(0)` if `pieces` is empty.
#'
#' @keywords internal
merge_pieces <- function(pieces, maxsize, overlap) {
  chunks <- character()
  window <- character()
  total  <- 0L
  for (p in pieces) {
    len <- stringr::str_length(p)
    if (total + len > maxsize && length(window) > 0) {
      chunks <- c(chunks, paste(window, collapse = ""))
      while (length(window) > 0 && (total > overlap || total + len > maxsize)) {
        total  <- total - stringr::str_length(window[1])
        window <- window[-1]
      }
    }
    window <- c(window, p)
    total  <- total + len
  }
  if (length(window) > 0) {
    chunks <- c(chunks, paste(window, collapse = ""))
  }
  chunks
}
