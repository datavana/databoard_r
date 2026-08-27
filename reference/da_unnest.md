# Unnest the `.task_result` list-column into regular columns

Expands the tibble-valued `.task_result` column into one column per
result field. If the resulting columns already exist in `data`, only
rows that actually carry a task result (i.e. where `.task_result` is not
`NA`) are updated; other rows keep their existing values. The `.task_id`
and `.task_state` columns are moved to the end.

## Usage

``` r
da_unnest(data)
```

## Arguments

- data:

  A data frame containing a `.task_result` list-column. If the column is
  absent, `data` is returned unchanged.

## Value

The data frame with `.task_result` unnested into individual columns.
