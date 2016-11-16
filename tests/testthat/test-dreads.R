context("dreads")

envs <- list(test = list(dir_path = "", hive = TRUE))

test_that("no error for no files found", {
  expect_equivalent(csmtools::dreads(envs, pattern = "a ridiculous pattern no directory will match"), data.table::data.table())
})


