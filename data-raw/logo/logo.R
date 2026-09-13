#
# Create hex-sticker ----
#

library(tidyverse)
library(hexSticker)


s <- sticker(
  "data-raw/logo/logo.png",
  package = "databoard",

  # Image positioning and sizing
  s_x = 1,                 # subplot x position
  s_y = 0.8,              # subplot y position
  s_width = 0.5,           # subplot width
  s_height = 0.5,          # subplot height

  # Package name styling
  p_size = 20,             # font size
  p_x = 1,                 # text x position
  p_y = 1.4,               # text y position
  p_color = "#4CAF50",     # text color

  # Hexagon styling
  h_fill = "white",      # hexagon fill color
  h_color = "#4CAF50",     # hexagon border color
  h_size = 2,

  filename = "data-raw/logo/logo_hex.png"
)

plot(s)

usethis::use_logo("man/logo_hex.png", geometry = "240x278", retina = TRUE)
