# Split a text column into overlapping chunks

Splits the text in a data frame column into chunks of at most `maxsize`
characters, preferring natural boundaries. The text is first split at
blank lines (paragraphs). Pieces that are still too long are split at
line breaks, then at word breaks, and finally at character level. Small
pieces are then greedily merged back together up to `maxsize`. The
trailing pieces of each chunk are repeated at the start of the next
chunk to create an overlap of up to `overlap` characters.

## Usage

``` r
chunk_text(
  df,
  col,
  maxsize = 1000,
  overlap = 100,
  separators = c("\n\\s*\n", "\n", "[ \t]+")
)
```

## Arguments

- df:

  A data frame or tibble.

- col:

  \<[`data-masking`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  The text column to chunk, given unquoted (tidyverse style). Must be a
  character column.

- maxsize:

  Maximum chunk size in characters. A single positive number.

- overlap:

  Target overlap in characters between consecutive chunks of the same
  text. Must be non-negative and smaller than `maxsize`. Overlap is
  built from whole pieces (paragraphs, lines, words), so the actual
  overlap is *up to* `overlap` characters. Only the character-level
  fallback produces an exact overlap.

- separators:

  Character vector of regular expressions, tried in order from coarsest
  to finest. The default splits at blank lines, then line breaks, then
  whitespace between words. A character-level fallback is always
  appended automatically.

## Value

A tibble with one row per chunk. It contains all columns of `df`, with
`col` holding the chunk text and two additional columns placed directly
after `col`:

- `chunk`:

  Running chunk number within each original row (integer).

- `chunk_size`:

  Number of characters in the chunk (integer).

Rows where `col` is `NA` or empty are kept, with `NA` text and
`chunk_size`.

## Details

The chunk text replaces the content of `col` (the column name is kept),
so the result can be piped directly into functions that expect the
original column, e.g. `llm_annotate(text, rules)`. All other columns are
carried along unchanged.

Chunks are trimmed of leading and trailing whitespace, so `chunk_size`
refers to the trimmed text. Sizes are measured in characters, not
tokens. As a rough rule of thumb, one token is about 4 characters for
English text.

## Examples

``` r
df <- tibble::tibble(
  doc  = c("a", "b"),
  text = c(
    "First paragraph.\n\nSecond paragraph,\nwith two lines.\n\nThird.",
    "Averyveryverylongwordwithoutanyspacesthatmustbecut"
  )
)

chunk_text(df, text, maxsize = 30, overlap = 10)
#> Error in chunk_text(df, text, maxsize = 30, overlap = 10): could not find function "chunk_text"

# Add sentence boundaries between line and word breaks
chunk_text(
  df, text, maxsize = 30, overlap = 10,
  separators = c("\n\\s*\n", "\n", "(?<=[.!?])\\s+", "[ \t]+")
)
#> Error in chunk_text(df, text, maxsize = 30, overlap = 10, separators = c("\n\\s*\n",     "\n", "(?<=[.!?])\\s+", "[ \t]+")): could not find function "chunk_text"
```
