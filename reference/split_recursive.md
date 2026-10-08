# Recursively split text using a hierarchy of separators

Splits `x` at the first separator in `separators` that occurs in the
text. Pieces that fit into `maxsize` are collected and merged with
[`merge_pieces()`](https://datavana.github.io/databoard_r/reference/merge_pieces.md).
Pieces that are still too long are split recursively with the remaining,
finer separators. The empty separator `""` triggers a hard
character-level split via
[`split_hard()`](https://datavana.github.io/databoard_r/reference/split_hard.md).

## Usage

``` r
split_recursive(x, maxsize, overlap, separators)
```

## Arguments

- x:

  A single character string.

- maxsize:

  Maximum chunk size in characters.

- overlap:

  Target overlap in characters.

- separators:

  Character vector of regexes, ordered from coarsest to finest, ending
  with `""`.

## Value

A character vector of chunks, each at most `maxsize` characters.
