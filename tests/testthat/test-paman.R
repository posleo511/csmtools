context("paman")

test_that("correct values are returned", {
  expect_equivalent(csmtools::paman(matrix(runif(9), nrow = 3, dimnames = list(LETTERS[1:3], LETTERS[4:6])), "From: ", y, " to: ", x),
                    structure(c("From: D to: A", "From: D to: B", "From: D to: C",
                                "From: E to: A", "From: E to: B", "From: E to: C", "From: F to: A",
                                "From: F to: B", "From: F to: C"), .Dim = c(3L, 3L)))
})

test_that("invalid data is handled correctly", {
  expect_error(csmtools::paman(NULL), "Unable to coerce 'x' to a matrix!")
  expect_error(csmtools::paman(NA))
  expect_error(csmtools::paman(list()))
  expect_error(csmtools::paman(1:4))
})
