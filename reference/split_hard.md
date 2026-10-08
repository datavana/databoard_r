# Hard split a string at character level

Cuts `x` into windows of `maxsize` characters, each starting
`maxsize - overlap` characters after the previous one. This produces an
exact overlap of `overlap` characters. Trailing windows that would only
repeat the overlap are dropped.

## Usage

``` r
split_hard(x, maxsize, overlap)
```

## Arguments

- x:

  A single character string.

- maxsize:

  Maximum chunk size in characters.

- overlap:

  Exact overlap in characters (must be `< maxsize`).

## Value

A character vector of chunks, each at most `maxsize` characters.
