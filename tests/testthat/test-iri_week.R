context("iri_week")

test_that("default date format works correctly", {
  expect_equal(csmtools::iri_week("2016-10-23"), 1938)
})

test_that("missingness type is preserved", {
  expect_identical(csmtools::iri_week(NA_character_), NA_character_)
  expect_identical(csmtools::iri_week(NA_complex_), NA_complex_)
  expect_identical(csmtools::iri_week(NA_integer_), NA_integer_)
  expect_identical(csmtools::iri_week(NA_real_), NA_real_)
})

test_that("additional arguments to 'as.Date' handled", {
  expect_equal(csmtools::iri_week(1, origin = "2000-01-01", tz = "NZ"), 1061)
})

test_that("vector inputs are handled", {
  expect_equal(csmtools::iri_week(15:16, origin = "2000-01-01"), 1063:1064)
})

test_that("null values are handled", {
  expect_null(csmtools::iri_week(NULL))
  expect_length(csmtools::iri_week(c(NA, NULL)), 1)
})

