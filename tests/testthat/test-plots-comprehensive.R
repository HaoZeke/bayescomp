test_that("bc_plot_dumbbell returns ggplot with 2-method simulated data", {
  data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2, seed = 301)
  p <- bc_plot_dumbbell(data, response = "count")
  expect_s3_class(p, "ggplot")
})

test_that("bc_plot_dumbbell errors with 3 methods", {
  data <- bc_simulate_benchmark(n_systems = 5, n_methods = 3,
                                true_effect = c(log(0.5), log(0.8)), seed = 302)
  expect_error(bc_plot_dumbbell(data, response = "count"), "exactly 2")
})

test_that("bc_plot_dumbbell with cap_value parameter", {
  data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2, seed = 303)
  p <- bc_plot_dumbbell(data, response = "count", cap_value = 400)
  expect_s3_class(p, "ggplot")
})

test_that("bc_plot_dumbbell with show_labels=FALSE", {
  data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2, seed = 304)
  p <- bc_plot_dumbbell(data, response = "count", show_labels = FALSE)
  expect_s3_class(p, "ggplot")
})

test_that("bc_plot_dumbbell errors on missing columns", {
  data <- data.frame(x = 1)
  expect_error(bc_plot_dumbbell(data), "not found")
})

test_that("bc_plot_violin returns ggplot", {
  data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2, seed = 305)
  p <- bc_plot_violin(data, response = "count")
  expect_s3_class(p, "ggplot")
})

test_that("bc_plot_violin with log_y=TRUE", {
  data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2, seed = 306)
  p <- bc_plot_violin(data, response = "count", log_y = TRUE)
  expect_s3_class(p, "ggplot")
})

test_that("bc_plot_violin with 3 methods", {
  data <- bc_simulate_benchmark(n_systems = 10, n_methods = 3,
                                true_effect = c(log(0.5), log(0.8)), seed = 307)
  p <- bc_plot_violin(data, response = "count")
  expect_s3_class(p, "ggplot")
})

test_that("bc_plot_violin errors on missing columns", {
  data <- data.frame(x = 1)
  expect_error(bc_plot_violin(data), "not found")
})

test_that("bc_plot_method_diff returns ggplot", {
  data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2, seed = 308)
  p <- bc_plot_method_diff(data, response = "count")
  expect_s3_class(p, "ggplot")
})

test_that("bc_plot_method_diff with as_ratio=FALSE", {
  data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2, seed = 309)
  p <- bc_plot_method_diff(data, response = "count", as_ratio = FALSE)
  expect_s3_class(p, "ggplot")
})

test_that("bc_plot_method_diff errors with 3 methods", {
  data <- bc_simulate_benchmark(n_systems = 5, n_methods = 3,
                                true_effect = c(log(0.5), log(0.8)), seed = 310)
  expect_error(bc_plot_method_diff(data, response = "count"), "exactly 2")
})

test_that("bc_plot_method_diff errors on missing columns", {
  data <- data.frame(x = 1)
  expect_error(bc_plot_method_diff(data), "not found")
})

test_that("bc_plot_scatter_comparison returns ggplot", {
  data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2, seed = 311)
  p <- bc_plot_scatter_comparison(data, response = "count")
  expect_s3_class(p, "ggplot")
})

test_that("bc_plot_scatter_comparison with log_scale=FALSE", {
  data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2, seed = 312)
  p <- bc_plot_scatter_comparison(data, response = "count", log_scale = FALSE)
  expect_s3_class(p, "ggplot")
})

test_that("bc_plot_scatter_comparison errors with 3 methods", {
  data <- bc_simulate_benchmark(n_systems = 5, n_methods = 3,
                                true_effect = c(log(0.5), log(0.8)), seed = 313)
  expect_error(bc_plot_scatter_comparison(data, response = "count"), "exactly 2")
})

test_that("bc_plot_scatter_comparison errors on missing columns", {
  data <- data.frame(x = 1)
  expect_error(bc_plot_scatter_comparison(data), "not found")
})

test_that("bc_plot_cactus returns ggplot", {
  data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2, seed = 314)
  p <- bc_plot_cactus(data, response = "count")
  expect_s3_class(p, "ggplot")
})

test_that("bc_plot_cactus with log_x=TRUE", {
  data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2, seed = 315)
  p <- bc_plot_cactus(data, response = "count", log_x = TRUE)
  expect_s3_class(p, "ggplot")
})

test_that("bc_plot_cactus with 3 methods", {
  data <- bc_simulate_benchmark(n_systems = 10, n_methods = 3,
                                true_effect = c(log(0.5), log(0.8)), seed = 316)
  p <- bc_plot_cactus(data, response = "count")
  expect_s3_class(p, "ggplot")
})

test_that("bc_plot_cactus with custom max_budget", {
  data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2, seed = 317)
  p <- bc_plot_cactus(data, response = "count", max_budget = 1000)
  expect_s3_class(p, "ggplot")
})

test_that("bc_plot_performance_profile returns ggplot", {
  data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2, seed = 318)
  p <- bc_plot_performance_profile(data, response = "count")
  expect_s3_class(p, "ggplot")
})

test_that("bc_plot_performance_profile with custom max_ratio", {
  data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2, seed = 319)
  p <- bc_plot_performance_profile(data, response = "count", max_ratio = 5)
  expect_s3_class(p, "ggplot")
})

test_that("bc_plot_performance_profile with 3 methods", {
  data <- bc_simulate_benchmark(n_systems = 10, n_methods = 3,
                                true_effect = c(log(0.5), log(0.8)), seed = 320)
  p <- bc_plot_performance_profile(data, response = "count")
  expect_s3_class(p, "ggplot")
})

test_that("bc_plot_contrasts returns ggplot from mock tibble", {
  mock <- data.frame(
    contrast = c("B - A", "C - A"),
    estimate = c(-0.5, -0.3),
    lower = c(-0.8, -0.6),
    upper = c(-0.2, 0.0)
  )
  p <- bc_plot_contrasts(mock)
  expect_s3_class(p, "ggplot")
  # Verify it has layers
  expect_true(length(p$layers) >= 2)
})

test_that("bc_plot_contrasts with custom colors", {
  mock <- data.frame(
    contrast = c("B - A"),
    estimate = c(-0.5),
    lower = c(-0.8),
    upper = c(-0.2)
  )
  p <- bc_plot_contrasts(mock, colors = c("#FF0000"))
  expect_s3_class(p, "ggplot")
})

test_that("bc_plot_pareto_k errors on wrong input type", {
  expect_error(bc_plot_pareto_k(list(x = 1)), "loo")
  expect_error(bc_plot_pareto_k(data.frame(x = 1)), "loo")
  expect_error(bc_plot_pareto_k("not_a_loo"), "loo")
})

test_that("theme_bayescomp returns a ggplot2 theme", {
  th <- theme_bayescomp()
  expect_s3_class(th, "theme")
  expect_s3_class(th, "gg")
})

test_that("theme_bayescomp with custom base_size", {
  th <- theme_bayescomp(base_size = 18)
  expect_s3_class(th, "theme")
})

test_that("scale_color_bayescomp returns a ggplot2 scale", {
  sc <- scale_color_bayescomp()
  expect_s3_class(sc, "Scale")
})

test_that("scale_colour_bayescomp is an alias for scale_color_bayescomp", {
  expect_identical(scale_colour_bayescomp, scale_color_bayescomp)
})

test_that("scale_fill_bayescomp returns a ggplot2 scale", {
  sc <- scale_fill_bayescomp()
  expect_s3_class(sc, "Scale")
})

test_that("scale_fill_bayescomp with reverse=TRUE returns a scale", {
  sc <- scale_fill_bayescomp(reverse = TRUE)
  expect_s3_class(sc, "Scale")
})

test_that("bc_colors is a named character vector", {
  expect_type(bc_colors, "character")
  expect_true(length(bc_colors) >= 8)
  expect_true(all(nzchar(names(bc_colors))))
  expect_true("teal" %in% names(bc_colors))
  expect_true("coral" %in% names(bc_colors))
})

test_that("bc_colors_discrete is a named character vector", {
  expect_type(bc_colors_discrete, "character")
  expect_true(length(bc_colors_discrete) >= 8)
  expect_true(all(nzchar(names(bc_colors_discrete))))
})

test_that("bc_plot_dumbbell with gamma-family data (time response)", {
  data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2,
                                family = "gamma", seed = 321)
  p <- bc_plot_dumbbell(data, response = "time")
  expect_s3_class(p, "ggplot")
})

test_that("bc_plot_violin with gamma-family data", {
  data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2,
                                family = "gamma", seed = 322)
  p <- bc_plot_violin(data, response = "time")
  expect_s3_class(p, "ggplot")
})

test_that("bc_plot_cactus with gamma-family data", {
  data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2,
                                family = "gamma", seed = 323)
  p <- bc_plot_cactus(data, response = "time")
  expect_s3_class(p, "ggplot")
})

test_that("bc_plot_performance_profile with gamma-family data", {
  data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2,
                                family = "gamma", seed = 324)
  p <- bc_plot_performance_profile(data, response = "time")
  expect_s3_class(p, "ggplot")
})

test_that("bc_plot_method_diff with sort_by parameter", {
  data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2, seed = 325)
  data$barrier <- runif(nrow(data), 0.5, 1.5)
  p <- bc_plot_method_diff(data, response = "count", sort_by = "barrier")
  expect_s3_class(p, "ggplot")
})

test_that("bc_plot_scatter_comparison with custom colors", {
  data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2, seed = 326)
  p <- bc_plot_scatter_comparison(data, response = "count",
                                   colors = c("#FF0000", "#0000FF"))
  expect_s3_class(p, "ggplot")
})
