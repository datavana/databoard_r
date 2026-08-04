#
# Test annotation extraction
#

library(testthat)
library(databoard)

test_that("extract_annos parses annotated segments", {
  result <- databoard:::extract_annos('Francis Ford <anno value="PERSON">Coppola</anno> and <anno value="PLACE">New York</anno>')

  expect_equal(nrow(result), 2L)
  expect_equal(result$value, c("PERSON", "PLACE"))
  expect_equal(result$segment, c("Coppola", "New York"))
})

test_that("extract_annos returns an empty tibble for plain text", {
  result <- databoard:::extract_annos("No annotations here.")

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0L)
  expect_equal(names(result), c("value", "segment"))
})
