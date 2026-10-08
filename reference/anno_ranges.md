# Extract segment text and character offsets

Pulls both the plain text and the character-offset ranges for all
elements stamped by
[`anno_offsets()`](https://datavana.github.io/databoard_r/reference/anno_offsets.md).
Works vectorized over the selected node set, so repeated extraction from
the same annotated document is cheap.

## Usage

``` r
anno_ranges(
  doc,
  tagid = NULL,
  tagname = NULL,
  attrname = if (is.null(tagname)) "id" else NULL
)
```

## Arguments

- doc:

  One of: an `xml2::xml_document` already processed by
  [`anno_offsets()`](https://datavana.github.io/databoard_r/reference/anno_offsets.md);
  a character value containing raw XML, which is annotated on the fly
  using `tagname` / `attrname`; or `NULL` / `NA`, in which case `NA`
  values are returned. Pass a pre-annotated document when extracting
  several values from the same content, to avoid re-parsing.

- tagid:

  Optional character vector of values of `attrname` (`id` by default) to
  keep. If `NULL`, all offset-annotated elements are returned.

- tagname, attrname:

  Element selection, see
  [`anno_offsets()`](https://datavana.github.io/databoard_r/reference/anno_offsets.md).
  Used for annotating character input; `attrname` also determines the
  `value` column and what `tagid` is matched against.

## Value

A list with elements:

- segments:

  Text pieces joined by `;`.

- offsets:

  Ranges as `"start-end"` joined by `;` (1-based, inclusive).

- length:

  Character length of the full plain text.

- coverage:

  Share of the plain text covered by the union of all segments.

- ranges:

  A one-element list holding a data frame with columns `id`, `tag`,
  `value`, `start`, `end`, `text`, `length` (one row per matching
  element). `start`/`end` can be passed directly to
  `IRanges::IRanges()`.

## Details

Multiple matches (e.g. discontinuous annotations sharing an `id`, or
several segments with the same code) yield multiple spans, returned in
document order so that `segments` and `offsets` align
element-for-element.

## See also

[`anno_offsets()`](https://datavana.github.io/databoard_r/reference/anno_offsets.md),
[`covered_length()`](https://datavana.github.io/databoard_r/reference/covered_length.md)
