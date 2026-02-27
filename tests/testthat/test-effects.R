test_that("bc_summarize_effects errors on non-brmsfit", {
  expect_error(bc_summarize_effects(lm(1 ~ 1)), "brmsfit")
})

test_that("bc_effect_table errors on non-brmsfit", {
  expect_error(bc_effect_table(lm(1 ~ 1)), "brmsfit")
})

test_that("bc_pairwise_contrasts errors on non-brmsfit", {
  expect_error(bc_pairwise_contrasts(lm(1 ~ 1)), "brmsfit")
})

test_that("bc_report errors on non-brmsfit", {
  expect_error(bc_report(lm(1 ~ 1)), "brmsfit")
})

test_that("bc_plot_contrasts returns ggplot from tibble", {
  mock_contrasts <- data.frame(
    contrast = c("B - A", "C - A", "C - B"),
    estimate = c(-0.5, -0.3, 0.2),
    lower = c(-0.8, -0.6, -0.1),
    upper = c(-0.2, 0.0, 0.5)
  )
  p <- bc_plot_contrasts(mock_contrasts)
  expect_s3_class(p, "ggplot")
})

test_that("bc_plot_contrasts errors on bad input", {
  expect_error(bc_plot_contrasts(data.frame(x = 1)), "contrast")
})
