# Split a string at a regex, keeping the separators

Splits `x` at every match of `sep` and attaches each separator to the
preceding piece. Pasting the pieces back together reproduces the
original text exactly.

## Usage

``` r
split_keep(x, sep)
```

## Arguments

- x:

  A single character string.

- sep:

  A regular expression (non-empty).

## Value

A character vector of non-empty pieces. Returns `x` unchanged if `sep`
does not occur in it.
