# Databoard Package

The databoard package is designed to interface with the databoard
service, enabling automated content coding via large language models.

The primary purpose of this package is to streamline work in R: by
providing a minimal set of intuitive functions, it simplifies the
process of submitting content for analysis and retrieving structured
output — reducing setup overhead and facilitating reproducible
workflows.

## How to install the databoard package?

Databoard can be installed from source using the remotes package.

``` r


library(remotes)
remotes::install_github("datavana/databoard_r", build_manual = TRUE, build_vignettes = TRUE)
```

To use the databoard service you need credentials. Please contact the
[Digital Media and Computational
Methods](https://www.uni-muenster.de/Kowi/en/institut/arbeitsbereiche/digital-media-computational-methods.shtml)
research unit to obtain a username and password.

Once you have credentials, you can log into the service. The
[`da_login()`](https://datavana.github.io/databoard_r/reference/da_login.md)method
prompts for the username and the password (alternatively, provide them
in the parameters).

``` r


library(databoard)
da_login()
```

This login process stores your access token for the databoard API
service invisibly in the system environment. The login lasts for one
session, after closing RStudio you have to renew the login process.

## How to use the databoard package?

The service provides three main functions:

- code text
- summarize text
- annotate text

``` r


library(tidyverse)

# Get example data
df <- databoard::movies

# Define coding rules
rules <- tibble::tribble(
  ~category,  ~description,                                                               ~example,
  "History",  "Movies based on real events or people from the past.",                     "Schindler’s List, Braveheart",
  "Scifi",    "Stories about futuristic science, technology, space, or alien life.",      "Interstellar, Blade Runner",
  "Musical",  "Films where characters sing and dance as part of the story.",              "The Greatest Showman, Mamma Mia",
  "Fantasy",  "Movies featuring magical or supernatural elements and imaginary worlds.",  "Pan’s Labyrinth, Harry Potter",
  "Comedy",   "Films made to entertain and make the audience laugh.",                     "Mean Girls, The Hangover",
  "Drama",    "Serious stories focused on relationships, and character development.",     "Forrest Gump, A Beautiful Mind"
)

write_rds(rules,"data/genres.rda")

# Submit to the databoard service
results <- llm_code(movies, abstract, rules)

# Once you submitted your tasks, 
# call the same method with  your data frame as the first parameter.
# Task results that are ready will be added.
# Keep calling until all tasks are finished.
results <- llm_code(results)

# Inspect result
results |> 
  count(llm_result)
  
```

See the introduction vignette for further examples.

## Authors and citation

**Authors**

Katharina Maubach (University of Münster)  
Jakob Jünger (University of Münster)

**Citation**
