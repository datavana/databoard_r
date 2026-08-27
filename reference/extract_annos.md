# Extract annotation spans from llm_result

Internal helper used by
[`llm_annotate()`](https://datavana.github.io/databoard_r/reference/llm_annotate.md):
parses `<anno value="...">...</anno>` tags and returns a tibble with
`value` and `segment`.

## Usage

``` r
extract_annos(text)
```

## Arguments

- text:

  Character scalar containing annotated text.

## Value

A tibble with columns `value` and `segment`.
