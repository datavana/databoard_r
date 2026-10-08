# Build a (hierarchical) REFI codebook

Adds `<Code>` elements for the given code names to a `<Codes>` node. If
`code_sep` is given, code names are split into hierarchy levels and
parent codes are created as needed. Each parent is created once, even if
it is shared by several subcodes.

## Usage

``` r
refi_build_codebook(codes_node, codes, code_sep = NULL)
```

## Arguments

- codes_node:

  An `xml2` node (the `<Codes>` element of the project).

- codes:

  Character vector of unique code names.

- code_sep:

  Optional separator for hierarchical code names.

## Value

A named character vector mapping each element of `codes` to the GUID of
its (leaf) `<Code>` element.

## See also

`as_refi()`
