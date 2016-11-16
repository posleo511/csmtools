context("pamel")

test_that("correct values are returned", {
  expect_equivalent(csmtools::pamel(3, "Letter ", matrix(LETTERS[seq(9)], nrow = 3), " is great"),
                    structure(c("Letter A is great", "Letter B is great", "Letter C is great",
                                "Letter D is great", "Letter E is great", "Letter F is great",
                                "Letter G is great", "Letter H is great", "Letter I is great"
                    ), .Dim = c(3L, 3L)))
})



