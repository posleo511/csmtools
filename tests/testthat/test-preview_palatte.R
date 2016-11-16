context("preview_palatte")

test_that("NA values throw errors appropriately", {
  expect_warning(csmtools::preview_palatte(c(NA, "#FFFFFF", "#8EC7FF")),
                 "One or more colors are NA!")
  expect_error(csmtools::preview_palatte(NULL), "Argument 'x' is NULL!")
  expect_error(csmtools::preview_palatte(c("#00")), "Not valid colors: #00")
})

