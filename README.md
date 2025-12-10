---
output: github_document
editor_options: 
  markdown: 
    wrap: 72
---

<!-- README.md is generated from README.Rmd. Please edit that file -->

```{r, include = FALSE}
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  fig.path = "man/figures/README-",
  out.width = "100%"
)
```

# Databoard-Package 

<!-- badges: start -->

<!-- badges: end -->

Automated Content Coding with Large Language Models

##Introduction to the Databoard

The **databoard package** is designed to interface with the **databoard service**, enabling automated content coding via large language models. The service is hosted by the Department of Communication at the University of Münster and leverages the internally available model Mixtral 8x7B.

Access to the service is granted to authorized users only — please contact Jakob Jünger to obtain a username and password. Once credentials are issued, users may retrieve answers from the databoard from a variety of environments (e.g. Facepager, Python scripts, or R scripts).

The primary purpose of this package is to streamline work in R: by providing a minimal set of intuitive functions, it simplifies the process of submitting content for analysis and retrieving coded output — reducing setup overhead and facilitating reproducible workflows.

## Getting started

    

```{r, eval=FALSE}         
# Install the package (see below), then load it
library(databoard)

# Get access token from your individual username and password and store it invisibly in the system environment
get_token("username", "pw")

# Submit a task to the databoard servive
submit_task(input, 
submit_task()
```

See further examples in `vignette("gettingstarted", package="databoard")`.

## Concept

The databoard package is made for easily accessing the databoard service, which helps to automatically code, summarize or tokenize textual content. 

## Examples

### Data preparation  



## Authors and citation

**Authors**\

Jakob Jünger (University of Münster)\
Katharina Maubach (University of Münster)\

**Citation**\


