# Parse one annotated text for REFI export

Annotates a single XML fragment with
[`anno_offsets()`](https://datavana.github.io/databoard_r/reference/anno_offsets.md),
extracts the coded segments with
[`anno_ranges()`](https://datavana.github.io/databoard_r/reference/anno_ranges.md),
and returns the plain text together with the codings. Elements with a
missing or empty code and empty (zero-width) elements are dropped with a
warning.

## Usage

``` r
refi_parse_text(x, tagname = "anno", code_attr = "value", label = NULL)
```

## Arguments

- x:

  A single character value with inline XML annotations, or `NA` (treated
  as an empty text).

- tagname:

  Character vector of annotation element names.

- code_attr:

  Name of the attribute holding the code name.

- label:

  Optional label (e.g. row and document name) used to prefix error and
  warning messages.

## Value

A list with elements `text` (plain text, character) and `codings` (data
frame with columns `code`, `start`, `end`; 1-based, inclusive).

## See also

`as_refi()`
