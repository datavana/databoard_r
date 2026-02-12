# Helper function for NULL coalescing
`%||%` <- function(x, y) if (is.null(x)) y else x
