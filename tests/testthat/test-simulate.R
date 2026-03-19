test_that("bc_simulate_benchmark with 3 methods and scalar true_effect", {
  data <- bc_simulate_benchmark(n_systems = 8, n_methods = 3,
                                true_effect = log(0.7), seed = 200)
  expect_s3_class(data, "tbl_df")
  expect_equal(nrow(data), 24)
  expect_equal(nlevels(data$method), 3)
  expect_equal(levels(data$method), c("method_1", "method_2", "method_3"))
  expect_true(is.factor(data$system_id))
  expect_true(is.factor(data$method))
  expect_true(all(data$count >= 0))
})

test_that("bc_simulate_benchmark with 4 methods and per-method effects", {
  data <- bc_simulate_benchmark(
    n_systems = 5, n_methods = 4,
    true_effect = c(log(0.5), log(0.8), log(1.2)), seed = 201
  )
  expect_equal(nrow(data), 20)
  expect_equal(nlevels(data$method), 4)
  expect_equal(levels(data$method),
               c("method_1", "method_2", "method_3", "method_4"))
})

test_that("bc_simulate_benchmark with censoring creates correct columns", {
  data <- bc_simulate_benchmark(n_systems = 30, n_methods = 2,
                                cens_threshold = 300, seed = 202)
  expect_true("censored" %in% names(data))
  expect_type(data$censored, "integer")
  expect_true(all(data$censored %in% c(0L, 1L)))
  expect_true(all(data$count <= 300))
  # With low threshold, at least some should be censored
  expect_true(any(data$censored == 1))
})

test_that("bc_simulate_benchmark gamma family has correct columns and types", {
  data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2,
                                family = "gamma", seed = 203)
  expect_true("time" %in% names(data))
  expect_false("count" %in% names(data))
  expect_true(all(data$time > 0))
  expect_type(data$time, "double")
  expect_true(is.factor(data$system_id))
  expect_true(is.factor(data$method))
})

test_that("bc_simulate_benchmark bernoulli family has correct columns", {
  data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2,
                                family = "bernoulli", seed = 204)
  expect_true("success" %in% names(data))
  expect_false("count" %in% names(data))
  expect_true(all(data$success %in% c(0, 1)))
})

test_that("bc_simulate_benchmark student family has correct columns", {
  data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2,
                                family = "student", seed = 205)
  expect_true("value" %in% names(data))
  expect_false("count" %in% names(data))
  expect_type(data$value, "double")
  # Student-t can have negative values
  # (not guaranteed but likely with intercept=0)
})

test_that("bc_simulate_benchmark seed reproducibility", {
  d1 <- bc_simulate_benchmark(n_systems = 10, n_methods = 2, seed = 999)
  d2 <- bc_simulate_benchmark(n_systems = 10, n_methods = 2, seed = 999)
  expect_identical(d1, d2)

  d3 <- bc_simulate_benchmark(n_systems = 10, n_methods = 2, seed = 1000)
  expect_false(identical(d1$count, d3$count))
})

test_that("bc_simulate_benchmark factor levels match method names", {
  data <- bc_simulate_benchmark(n_systems = 5, n_methods = 3,
                                true_effect = c(log(0.5), log(0.8)),
                                seed = 206)
  expect_equal(levels(data$method),
               c("method_1", "method_2", "method_3"))
  # System IDs are zero-padded
  sys_levels <- levels(data$system_id)
  expect_true(all(grepl("^sys_\\d{2}$", sys_levels)))
})

test_that("bc_simulate_benchmark censoring ignored for bernoulli/student", {
  data_bern <- bc_simulate_benchmark(n_systems = 5, family = "bernoulli",
                                      cens_threshold = 0.5, seed = 207)
  expect_false("censored" %in% names(data_bern))

  data_stud <- bc_simulate_benchmark(n_systems = 5, family = "student",
                                      cens_threshold = 0.5, seed = 208)
  expect_false("censored" %in% names(data_stud))
})

test_that("bc_simulate_benchmark with custom intercept", {
  data <- bc_simulate_benchmark(n_systems = 5, n_methods = 2,
                                intercept = log(100), seed = 209)
  # Mean count should be roughly around 100
  expect_true(mean(data$count) > 20)
  expect_true(mean(data$count) < 500)
})
