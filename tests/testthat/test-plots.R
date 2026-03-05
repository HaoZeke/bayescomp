test_that("theme_bayescomp returns a ggplot theme", {
  th <- theme_bayescomp()
  expect_s3_class(th, "theme")
})

test_that("scale_color_bayescomp returns a scale", {
  sc <- scale_color_bayescomp()
  expect_s3_class(sc, "Scale")
})

test_that("scale_fill_bayescomp returns a scale", {
  sc <- scale_fill_bayescomp()
  expect_s3_class(sc, "Scale")
})

test_that("bc_plot_pp errors on non-brmsfit", {
  expect_error(bc_plot_pp(lm(1 ~ 1)), "brmsfit")
})

test_that("bc_plot_conditional errors on non-brmsfit", {
  expect_error(bc_plot_conditional(lm(1 ~ 1), "x"), "brmsfit")
})

test_that("bc_plot_shape errors on non-brmsfit", {
  expect_error(bc_plot_shape(lm(1 ~ 1)), "brmsfit")
})

test_that("bc_plot_pareto_k errors on non-loo", {
  expect_error(bc_plot_pareto_k(lm(1 ~ 1)), "loo")
})

test_that("bc_plot_trace errors on non-brmsfit", {
  expect_error(bc_plot_trace(lm(1 ~ 1)), "brmsfit")
})

test_that("bc_dharma_check errors on non-brmsfit", {
  expect_error(bc_dharma_check(lm(1 ~ 1)), "brmsfit")
})

test_that("bc_plot_cactus works on simulated data", {
  data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2, seed = 99)
  p <- bc_plot_cactus(data, response = "count", method_col = "method")
  expect_s3_class(p, "ggplot")
})

test_that("bc_plot_cactus errors on missing column", {
  data <- data.frame(x = 1)
  expect_error(bc_plot_cactus(data), "not found")
})

test_that("bc_plot_performance_profile works on simulated data", {
  data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2, seed = 99)
  p <- bc_plot_performance_profile(data, response = "count",
                                    method_col = "method",
                                    system_col = "system_id")
  expect_s3_class(p, "ggplot")
})

test_that("bc_plot_performance_profile errors on missing columns", {
  data <- data.frame(x = 1)
  expect_error(bc_plot_performance_profile(data), "not found")
})

test_that("bc_plot_dumbbell works on simulated data", {
  data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2, seed = 101)
  p <- bc_plot_dumbbell(data, response = "count")
  expect_s3_class(p, "ggplot")
})

test_that("bc_plot_dumbbell errors with 3 methods", {
  data <- bc_simulate_benchmark(n_systems = 5, n_methods = 3,
                                true_effect = c(log(0.5), log(0.8)), seed = 102)
  expect_error(bc_plot_dumbbell(data), "exactly 2")
})

test_that("bc_plot_violin works on simulated data", {
  data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2, seed = 103)
  p <- bc_plot_violin(data, response = "count")
  expect_s3_class(p, "ggplot")
})

test_that("bc_plot_method_diff works on simulated data", {
  data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2, seed = 104)
  p <- bc_plot_method_diff(data, response = "count")
  expect_s3_class(p, "ggplot")
})

test_that("bc_plot_scatter_comparison works on simulated data", {
  data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2, seed = 105)
  p <- bc_plot_scatter_comparison(data, response = "count")
  expect_s3_class(p, "ggplot")
})

test_that("bc_plot_conditional accepts show_extrapolation parameter", {
  # Can't test the actual plot without a brmsfit, but verify the parameter exists
  expect_error(
    bc_plot_conditional(lm(1 ~ 1), "x", show_extrapolation = TRUE),
    "brmsfit"
  )
})

test_that("bc_filter_matching filters correctly", {
  data <- data.frame(
    system_id = factor(rep(c("s1", "s2", "s3"), each = 2)),
    method = factor(rep(c("A", "B"), 3)),
    count = c(100, 50, 200, 150, 300, 250),
    barrier = c(1.0, 1.005, 2.0, 2.5, 3.0, 3.002),
    success = c(TRUE, TRUE, TRUE, TRUE, TRUE, TRUE)
  )
  # s2 has barrier diff of 0.5 (> tol=0.01), should be filtered
  filtered <- bc_filter_matching(data, compare_col = "barrier", tol = 0.01)
  expect_equal(length(unique(filtered$system_id)), 2)  # s1 and s3
  expect_false("s2" %in% filtered$system_id)
})
