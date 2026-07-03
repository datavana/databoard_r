#
# Databoard configuration
#

DATABOARD_BASEURL <- "https://databoard.uni-muenster.de"


# Colour palette for known states; fallback to white
STATE_COLORS <- list(
  SUCCESS = cli::col_green,
  PENDING = cli::col_yellow,
  FAILURE = cli::col_red,
  RETRY   = cli::col_magenta,
  STARTED = cli::col_cyan,
  REVOKED = cli::col_silver
)
