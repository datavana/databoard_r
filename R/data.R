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
#' @source Communication Department of the University of Münster (<k.maubach@uni-muenster.de> and <jakob.juenger@uni-muenster.de>).
#'
#' @name movies
NULL

#' Movie Codebook
#'
#' An example codebook for the movies dataset
#'
#'
#' @format ## `movies_rules`
#' A data frame with 6 rows and 3 columns:
#' \describe{
#'   \item{category}{A category for coding featuring different movie genres}
#'   \item{description}{A description of the category to be coded}
#'   \item{example}{An example of code that should be coded within this category}
#' }
#' @source Communication Department of the University of Münster (<k.maubach@uni-muenster.de> and <jakob.juenger@uni-muenster.de>).
#'
#' @name movies_rules
NULL
