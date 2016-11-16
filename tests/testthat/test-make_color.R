context("make_color")

test_that("data types are handled correctly", {
  expect_equivalent(csmtools::make_color(NA, "black", "blackk", 5, "#00", "#000000", "rgb(1, 1, 1, 0.5)"),
               list("#FFFFFF", "#000000", FALSE, "#00FFFF", FALSE, "#000000", "#FFFFFF80"))
})

test_that("alternate data structures are handled correctly", {
  expect_equal(csmtools::make_color(c(NA, "black", "blackk", 5, "#00", "#000000", "rgb(1, 1, 1, 0.5)")),
               list("#FFFFFF", "#000000", FALSE, "#00FFFF", FALSE, "#000000", "#FFFFFF80"))
  expect_error(csmtools::make_color(data.frame(c(NA, "black", "blackk", 5, "#00", "#000000", "rgb(1, 1, 1, 0.5)"))),
               "Invalid datatype argument! Results in a list with items with length > 1!")
  expect_error(csmtools::make_color(list(c(NA, "black", "blackk", 5, "#00", "#000000", "rgb(1, 1, 1, 0.5)"))),
               "Invalid datatype argument! Results in a list with items with length > 1!")
})
