# Send a request to the databoard server

Send a request to the databoard server

## Usage

``` r
da_request(endpoint, body, wait = 0)
```

## Arguments

- endpoint:

  The path including a leading slash

- body:

  If provided, the body is send via a POST request. Otherwise, a GET
  request is issued.

- wait:

  Seconds to wait for an answer. Set to 0 to return immediately.

## Value

The response object.
