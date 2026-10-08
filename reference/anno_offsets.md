# Inject character offsets into selected XML elements

Walks the XML tree once in document order, accumulating a running
character offset over all text and CDATA nodes, and stamps `data-start`
and `data-end` attributes onto every selected element. Offsets are
1-based and inclusive, and refer to positions in the *plain*
(tag-stripped) text, i.e. `xml2::xml_text(xml2::xml_root(doc))`.

## Usage

``` r
anno_offsets(
  xml,
  tagname = NULL,
  attrname = if (is.null(tagname)) "id" else NULL
)
```

## Arguments

- xml:

  Character value containing XML text. May be a fragment with several
  top-level nodes.

- tagname:

  Character vector of element names to stamp, or `NULL`.

- attrname:

  Name of an attribute; elements carrying it are stamped. Defaults to
  `"id"` if `tagname` is `NULL`, otherwise to `NULL`.

## Value

An `xml2::xml_document` with `data-start` and `data-end` integer-valued
attributes injected onto all selected elements.

## Details

Elements are selected via `tagname` and/or `attrname`:

- only `tagname`: all elements with one of these names,

- only `attrname`: all elements carrying this attribute (default
  `"id"`),

- both: elements matching the name *and* carrying the attribute.

The input is wrapped in a synthetic `<root>` element so that XML
fragments with multiple top-level nodes can be parsed; this wrapper is
never stamped. Consequently, the input must not contain an XML
declaration or DOCTYPE. Mixed content is handled correctly: a parent
element's span covers both its text runs and its child elements, while
children span only their own content. Comment and processing-instruction
nodes are skipped, consistent with how
[`xml2::xml_text()`](http://xml2.r-lib.org/reference/xml_text.md) treats
them.

Empty elements (e.g. `<anno value="x"></anno>`) get `data-end` equal to
`data-start - 1`, i.e. a zero-width span.

## See also

[`anno_ranges()`](https://datavana.github.io/databoard_r/reference/anno_ranges.md)
