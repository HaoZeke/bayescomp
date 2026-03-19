test_that("bc_validate with zero-row data", {
  empty <- data.frame(
    count = numeric(0),
    method = factor(character(0)),
    system_id = factor(character(0))
  )
  # Zero rows means zero methods, should error
  expect_error(bc_validate(empty), "at least 2 methods")
})

test_that("bc_validate with single-row data", {
  single <- data.frame(
    count = 42,
    method = factor("A"),
    system_id = factor("s1")
  )
  # Single method should error
  expect_error(bc_validate(single), "at least 2 methods")
})

test_that("bc_validate converts non-factor method column with warning", {
  data <- data.frame(
    count = c(100, 50, 200, 150),
    method = rep(c("A", "B"), 2),
    system_id = factor(rep(c("s1", "s2"), each = 2))
  )
  expect_warning(bc_validate(data), "not a factor")
})

test_that("bc_validate converts non-factor system_id column with warning", {
  data <- data.frame(
    count = c(100, 50, 200, 150),
    method = factor(rep(c("A", "B"), 2)),
    system_id = rep(c("s1", "s2"), each = 2)
  )
  expect_warning(bc_validate(data), "not a factor")
})

test_that("bc_suggest_family with all-identical values", {
  y <- rep(42, 5)
  fam <- bc_suggest_family(y)
  # All identical non-negative integers: counts
  expect_equal(fam$family, "negbinomial")
})

test_that("bc_simulate_benchmark with n_systems=1", {
  data <- bc_simulate_benchmark(n_systems = 1, n_methods = 2, seed = 501)
  expect_equal(nrow(data), 2)
  expect_equal(nlevels(data$system_id), 1)
  expect_equal(nlevels(data$method), 2)
  expect_true(all(data$count >= 0))
})

test_that("bc_filter_matching with tol=0 filters almost everything", {
  data <- data.frame(
    system_id = factor(rep(c("s1", "s2", "s3"), each = 2)),
    method = factor(rep(c("A", "B"), 3)),
    count = c(100, 50, 200, 150, 300, 250),
    barrier = c(1.0, 1.001, 2.0, 2.0, 3.0, 3.001),
    success = c(TRUE, TRUE, TRUE, TRUE, TRUE, TRUE)
  )
  # With tol=0, only exact matches survive (s2 has barrier=2.0 for both)
  filtered <- bc_filter_matching(data, compare_col = "barrier", tol = 0)
  expect_equal(length(unique(filtered$system_id)), 1)
  expect_true("s2" %in% filtered$system_id)
})

test_that("bc_read_benchmark errors on non-existent file", {
  expect_error(
    bc_read_benchmark("/tmp/surely_does_not_exist_abc123.csv"),
    "File not found"
  )
})

test_that("bc_filter_matching errors on missing compare_col", {
  data <- bc_simulate_benchmark(n_systems = 5, n_methods = 2, seed = 502)
  expect_error(
    bc_filter_matching(data, compare_col = "nonexistent"),
    "not found"
  )
})

test_that("bc_validate with require_success=TRUE and missing success column", {
  data <- data.frame(
    count = c(100, 50, 200, 150),
    method = factor(rep(c("A", "B"), 2)),
    system_id = factor(rep(c("s1", "s2"), each = 2))
  )
  expect_error(bc_validate(data, require_success = TRUE), "Missing")
})

test_that("bc_simulate_benchmark preserves column types across families", {
  for (fam in c("negbinomial", "gamma", "bernoulli", "student")) {
    data <- bc_simulate_benchmark(n_systems = 3, n_methods = 2,
                                  family = fam, seed = 510)
    expect_true(is.factor(data$system_id),
                info = paste("system_id not factor for", fam))
    expect_true(is.factor(data$method),
                info = paste("method not factor for", fam))
    expect_equal(ncol(data), 3,
                 info = paste("wrong ncol for", fam))
  }
})

test_that("bc_plot_contrasts errors on missing required columns", {
  expect_error(bc_plot_contrasts(data.frame(x = 1)), "contrast")
  expect_error(
    bc_plot_contrasts(data.frame(contrast = "A", estimate = 1, lower = 0)),
    "contrast"
  )
})

test_that("bc_plot_cactus errors on missing method column", {
  data <- data.frame(count = 1:5)
  expect_error(bc_plot_cactus(data), "not found")
})

test_that("bc_plot_cactus errors on missing response column", {
  data <- data.frame(method = factor(c("A", "B")))
  expect_error(bc_plot_cactus(data), "not found")
})

test_that("bc_validate handles NaN in time column with require_time", {
  data <- data.frame(
    count = c(100, 50, 200, 150),
    method = factor(rep(c("A", "B"), 2)),
    system_id = factor(rep(c("s1", "s2"), each = 2)),
    time = c(1.0, NaN, 2.0, 1.5)
  )
  expect_error(bc_validate(data, require_time = TRUE), "NaN")
})

test_that("bc_validate handles Inf in time column with require_time", {
  data <- data.frame(
    count = c(100, 50, 200, 150),
    method = factor(rep(c("A", "B"), 2)),
    system_id = factor(rep(c("s1", "s2"), each = 2)),
    time = c(1.0, Inf, 2.0, 1.5)
  )
  expect_error(bc_validate(data, require_time = TRUE), "Inf")
})
