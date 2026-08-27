# Login to the Databoard service

Authenticates against the Databoard-API and stores the returned access
token in the system environment for subsequent calls. Please contact the
Digital Media and Computational Methods research unit to acquire a user
account. Keep your login data and access token private.

## Usage

``` r
da_login(
  username,
  password,
  server = getOption("databoard.baseurl", DATABOARD_BASEURL),
  verbose = FALSE,
  silent = TRUE
)
```

## Arguments

- username:

  Character. Username for the login. If missing, the user is prompted
  interactively.

- password:

  Character. Password for the login. If missing, the user is prompted
  interactively with a masked prompt (via the `askpass` package if
  available, otherwise an unmasked
  [`readline()`](https://rdrr.io/r/base/readline.html) fallback).

- server:

  Character. Base URL of the Databoard server. Defaults to
  `https://databoard.uni-muenster.de/`.

- verbose:

  Logical. If `TRUE`, subsequent API calls will print additional
  diagnostic information. Stored in the environment variable
  `DATABOARD_VERBOSE`.

- silent:

  Logical. If `TRUE`, failing API calls will not stop processing further
  tasks. Stored in the environment variable `DATABOARD_SILENT`.

## Value

Invisibly returns `TRUE` on successful login and `FALSE` otherwise. As a
side effect, sets the environment variables `DATABOARD_SERVER`,
`DATABOARD_ACCESSTOKEN`, and `DATABOARD_VERBOSE`.
