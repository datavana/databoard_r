
<!-- README.md is generated from README.Rmd. Please edit that file -->

# Databoard-Package

<!-- badges: start -->

<!-- badges: end -->

Automated Content Coding with Large Language Models.

## Introduction to the Databoard

The databoard package is designed to interface with the databoard
service, enabling automated content coding via large language models.
The service is hosted by the Department of Communication at the
University of Münster and leverages the internally available model
Mixtral 8x7B.

Access to the service is granted to authorized users only — please
contact the [Digital Media and Computational
Methods](https://www.uni-muenster.de/Kowi/en/institut/arbeitsbereiche/digital-media-computational-methods.shtml)
research unit to obtain a username and password. Once credentials are
issued, users may retrieve answers from the databoard from a variety of
environments (e.g. Facepager, Python scripts, or R scripts).

The primary purpose of this package is to streamline work in R: by
providing a minimal set of intuitive functions, it simplifies the
process of submitting content for analysis and retrieving coded output —
reducing setup overhead and facilitating reproducible workflows.

## How to use the databoard package?

First we load the package and get some data. Databoard can be installed
from source using the remotes package. We are currently working to
publish the package on cran. To try out the package you can use one of
the two internal dataframes *chat_gpt* or *movies*.

``` r
# Load the package
library(remotes)
remotes::install_github(datavana_databoard_r)

# Load an example data frame from the package
df_movies <- databoard::movies
df_chatgpt <- databoard::chatgpt
```

## Login into the service

To use the databoard service and the accompagnying package you need to
have credentials. To obtain these please contact the [Digital Media and
Computational
Methods](https://www.uni-muenster.de/Kowi/en/institut/arbeitsbereiche/digital-media-computational-methods.shtml)
research group. In the future we aim to open the service, but for now
this is the only ways to use the package.

Once you have your credentials which consists of a username and a
password you can log into the service. The login last for one session,
after closing RStudio you have to renew the login process.

``` r
# Login into the service
db_login("username", "password") # please note, both username and password must be enclosed in quotation marks. 
```

This login process stores your access token for the databoard API
service invisibly in the system environment.

## Core principles

TO BE ADDED

## The different functionalities of the databoard

We are in an ongoing process to add more functionalities to the
databoard. As of now the service provides three main functionalities: to
code text, to summarize text and to annotate text.

### Using the service to code text

``` r
llm_code()
```

### Using the service to summarize text

``` r
llm_summarize()
```

### Using the service to annotate text

## Additional Parameters

## Trouble Shooting

## Authors and citation

**Authors**  

Katharina Maubach (University of Münster)  
Jakob Jünger (University of Münster)

**Citation**  
