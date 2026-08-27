# Check whether all tasks have finished

Returns `TRUE` if no task in `data` is still in the `PENDING` state.

## Usage

``` r
da_finished(data)
```

## Arguments

- data:

  A data frame containing a `.task_state` column.

## Value

Logical scalar. `TRUE` if all tasks have left the `PENDING` state,
`FALSE` otherwise.
