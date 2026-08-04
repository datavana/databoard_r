#
# Databoard configuration
#

DATABOARD_BASEURL <- "https://databoard.uni-muenster.de"


# Colour palette for known states
STATE_COLORS <- list(
  SUCCESS = cli::col_green,
  PENDING = cli::col_yellow,
  FAILURE = cli::col_red,
  RETRY   = cli::col_magenta,
  STARTED = cli::col_cyan,
  REVOKED = cli::col_silver
)


DATABOARD_MAXRETRIES <- 3L


#
# Option handling
#

.onLoad <- function(libname, pkgname) {
  op <- options()
  op.databoard <- list(
    databoard.baseurl     = DATABOARD_BASEURL,
    databoard.max_retries = DATABOARD_MAXRETRIES
  )
  toset <- !(names(op.databoard) %in% names(op))
  if (any(toset)) options(op.databoard[toset])
  invisible()
}

