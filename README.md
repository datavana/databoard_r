
<!-- README.md is generated from README.Rmd. Please edit that file -->

# Databoard-Package

<!-- badges: start -->
<!-- badges: end -->

The databoard package is designed to interface with the databoard
service, enabling automated content coding via large language models.
The service is hosted by the Department of Communication at the
University of Münster and leverages the internally available model
Mixtral 8x7B.

The primary purpose of this package is to streamline work in R: by
providing a minimal set of intuitive functions, it simplifies the
process of submitting content for analysis and retrieving coded output —
reducing setup overhead and facilitating reproducible workflows.

## How to install the databoard package?

Databoard can be installed from source using the remotes package.

``` r

library(remotes)
remotes::install_github("datavana/databoard_r", build_manual = TRUE, build_vignettes = TRUE)
```

To use the databoard service and the accompagnying package you need to
have credentials. Please contact the [Digital Media and Computational
Methods](https://www.uni-muenster.de/Kowi/en/institut/arbeitsbereiche/digital-media-computational-methods.shtml)
research unit to obtain a username and password.

Once you have your credentials which consists of a username and a
password you can log into the service. The `da_login()`method prompts
for your credentials (alternatively, provide them in the parameters).

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
- annotate text (work in progress)

``` r

library(tidyverse)

# Get example data
df <- databoard::movies
rules <- databoard::movies_rules

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
