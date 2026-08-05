#
# Example data for coding rules
#

library(tidyverse)

genres <-tibble::tribble(
  ~category,  ~description,                                                               ~example,
  "History",  "Movies based on real events or people from the past.",                     "Schindler’s List, Braveheart",
  "Scifi",    "Stories about futuristic science, technology, space, or alien life.",      "Interstellar, Blade Runner",
  "Musical",  "Films where characters sing and dance as part of the story.",              "The Greatest Showman, Mamma Mia",
  "Fantasy",  "Movies featuring magical or supernatural elements and imaginary worlds.",  "Pan’s Labyrinth, Harry Potter",
  "Comedy",   "Films made to entertain and make the audience laugh.",                     "Mean Girls, The Hangover",
  "Drama",    "Serious stories focused on relationships, and character development.",     "Forrest Gump, A Beautiful Mind"
)

usethis::use_data(genres, overwrite = TRUE)
