# Greedily merge pieces into overlapping chunks

Concatenates consecutive pieces until adding the next one would exceed
`maxsize`. The chunk is then emitted, and pieces are dropped from its
front until at most `overlap` characters remain and the next piece fits.
The remaining pieces become the start (overlap) of the next chunk.

## Usage

``` r
merge_pieces(pieces, maxsize, overlap)
```

## Arguments

- pieces:

  Character vector of pieces, each at most `maxsize` characters.

- maxsize:

  Maximum chunk size in characters.

- overlap:

  Target overlap in characters.

## Value

A character vector of chunks, each at most `maxsize` characters. Returns
`character(0)` if `pieces` is empty.
