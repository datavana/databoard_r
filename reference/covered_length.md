# Total length covered by a set of ranges

Computes the number of positions covered by the *union* of 1-based,
inclusive integer ranges, so overlapping or nested ranges are counted
only once. Zero-width ranges (`end < start`, e.g. from empty elements)
and ranges containing `NA` are ignored.

## Usage

``` r
covered_length(start, end)
```

## Arguments

- start, end:

  Integer vectors of equal length with range boundaries (1-based,
  inclusive).

## Value

A single integer: the number of covered positions.

## Details

Equivalent to
`sum(IRanges::width(IRanges::reduce(IRanges::IRanges(start, end))))`,
but without the Bioconductor dependency.

## See also

[`anno_ranges()`](https://datavana.github.io/databoard_r/reference/anno_ranges.md)
