# Log out from the Databoard service

Clears the environment variables set by
[`da_login()`](https://datavana.github.io/databoard_r/reference/da_login.md)
(`DATABOARD_SERVER`, `DATABOARD_ACCESSTOKEN`, `DATABOARD_VERBOSE`, and
`DATABOARD_SILENT`), effectively ending the current session. Subsequent
API calls will fail until
[`da_login()`](https://datavana.github.io/databoard_r/reference/da_login.md)
is called again.

## Usage

``` r
da_logout()
```

## Value

Invisibly returns `TRUE`.

## See also

[`da_login()`](https://datavana.github.io/databoard_r/reference/da_login.md)
