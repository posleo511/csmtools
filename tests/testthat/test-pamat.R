context("pamat")

test_that("correct values are returned", {
  expect_equivalent(csmtools::pamat(matrix(LETTERS[1:9], nrow = 3), matrix(letters[1:9], nrow = 3), sep = " -> "),
                    structure(c("A -> a", "B -> b", "C -> c", "D -> d", "E -> e",
                                "F -> f", "G -> g", "H -> h", "I -> i"), .Dim = c(3L, 3L)))
})


