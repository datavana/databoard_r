# Split a single text into trimmed chunks

Wrapper around
[`split_recursive()`](https://datavana.github.io/databoard_r/reference/split_recursive.md)
that handles missing or empty input and trims the resulting chunks.

## Usage

``` r
split_text(x, maxsize, overlap, separators)
```

## Arguments

- x:

  A single character string.

- maxsize:

  Maximum chunk size in characters.

- overlap:

  Target overlap in characters.

- separators:

  Character vector of regexes, ending with `""`.

## Value

A character vector of non-empty, trimmed chunks. Returns `character(0)`
if `x` is `NA` or contains only whitespace.
