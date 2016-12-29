context("filter_files")

test_that("errors appropriately", {
  expect_error(csmtools::filter_files(NULL, size = 1, units = "KB"), "invalid 'file' argument")
  expect_error(csmtools::filter_files(NA, size = 1, units = "KB"), "invalid 'file' argument")
})
