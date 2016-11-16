context("gg_color_hue")

test_that("correct values are returned", {
  expect_equivalent(csmtools::gg_color_hue(5),
                    c("rgb(248,118,109)", "rgb(163,165,0)", "rgb(0,191,125)", "rgb(0,176,246)", "rgb(231,107,243)"))
  expect_equivalent(csmtools::gg_color_hue(5, rgb = FALSE),
                    c("#F8766D", "#A3A500", "#00BF7D", "#00B0F6", "#E76BF3"))
})

test_that("function fails for in appropriate values", {
  expect_error(csmtools::gg_color_hue(-1), "only 0's may be mixed with negative subscripts")
  expect_error(csmtools::gg_color_hue(NULL), "argument 'length.out' must be of length 1")
  expect_error(csmtools::gg_color_hue(NA), "length must be non-negative number")
  expect_error(csmtools::gg_color_hue(list()))
  expect_error(csmtools::gg_color_hue(data.table()))
})
