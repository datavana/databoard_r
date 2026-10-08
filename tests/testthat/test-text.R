#
# Test annotation extraction
#

library(testthat)
library(databoard)

test_that("chunks respect maxsize and keep other columns", {
  df <- tibble::tibble(
    id   = 1:2,
    text = c("Para one.\n\nPara two is longer\nand spans lines.",
             strrep("x", 95))
  )
  res <- chunk_text(df, text, maxsize = 20, overlap = 5)

  expect_true(all(res$chunk_size <= 20))
  expect_named(res, c("id", "text", "chunk", "chunk_size"))
  expect_equal(res$chunk[res$id == 2], seq_len(sum(res$id == 2)))
})

test_that("NA and empty texts are kept", {
  df  <- tibble::tibble(text = c(NA, "", "abc"))
  res <- chunk_text(df, text, maxsize = 10, overlap = 2)
  expect_equal(nrow(res), 3)
  expect_true(is.na(res$chunk_size[1]))
})

test_that("invalid arguments error", {
  df <- tibble::tibble(text = "abc")
  expect_error(chunk_text(df, text, maxsize = 10, overlap = 10))
  expect_error(chunk_text(df, nope))
})
