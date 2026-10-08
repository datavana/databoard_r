# Extract annotation spans from a character value

Internal helper used by
[`llm_annotate()`](https://datavana.github.io/databoard_r/reference/llm_annotate.md):
parses `<anno value="...">...</anno>` tags and returns a tibble with
`value` and `segment`. Parsing and span extraction are delegated to
[`anno_offsets()`](https://datavana.github.io/databoard_r/reference/anno_offsets.md)
and
[`anno_ranges()`](https://datavana.github.io/databoard_r/reference/anno_ranges.md).

## Usage

``` r
anno_extract(text, tagname = "anno", attrname = "value")
```

## Arguments

- text:

  Character scalar containing annotated text.

- tagname:

  Name of the annotation element.

- attrname:

  Name of the attribute holding the annotation value.

## Value

A tibble with columns `value` and `segment`.

## See also

[`anno_ranges()`](https://datavana.github.io/databoard_r/reference/anno_ranges.md),
[`anno_offsets()`](https://datavana.github.io/databoard_r/reference/anno_offsets.md)
