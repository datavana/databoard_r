#' Movie Dataset
#'

#' A fabricated data set containing information about different movies

#'
#'
#' @format ## `movies`
#' A data frame with 10 rows and 4 columns:
#' \describe{
#'   \item{id}{A running id number}
#'   \item{name}{Name of the moview}
#'   \item{abstract}{A short abstract, imagined from chatgpt based on the movie title}
#'   \item{year}{A review of the movie, imagined from chatgtp based on the movie title}
#' }

#' #' @source Communication Department of the University of Münster (<k.maubach@uni-muenster.de> and <jakob.juenger@uni-muenster.de>).
"movies"

#' Movie genre descriptions
#'
#' A rule set for coding genres
#'
#'
#' @format ## `genres`
#' A data frame with 6 rows and 3 columns:
#' \describe{
#'   \item{category}{The genre name}
#'   \item{description}{Definition ot the genre.}
#'   \item{example}{Example movies}
#' }
#' #' @source Communication Department of the University of Münster (<k.maubach@uni-muenster.de> and <jakob.juenger@uni-muenster.de>).
"genres"
