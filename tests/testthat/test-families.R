test_that("bc_suggest_family detects count data", {
  y <- c(100, 200, 50, 300, 80)
  fam <- bc_suggest_family(y)
  expect_equal(fam$family, "negbinomial")
  expect_equal(fam$link, "log")
})

test_that("bc_suggest_family detects binary data", {
  y <- c(TRUE, FALSE, TRUE, TRUE, FALSE)
  fam <- bc_suggest_family(y)
  expect_equal(fam$family, "bernoulli")
})

test_that("bc_suggest_family detects time data", {
  y <- c(1.5, 2.3, 0.8, 3.1, 1.2)
  fam <- bc_suggest_family(y)
  expect_equal(fam$family, "gamma")
})

test_that("bc_suggest_family respects explicit type", {
  y <- c(100, 200, 50)
  fam <- bc_suggest_family(y, type = "time")
  expect_equal(fam$family, "gamma")
})

test_that("bc_default_priors returns valid priors", {
  priors <- bc_default_priors()
  expect_s3_class(priors, "brmsprior")
  expect_true(nrow(priors) >= 3)
})

test_that("bc_default_priors adds shape prior when requested", {
  priors_no <- bc_default_priors(has_shape_submodel = FALSE)
  priors_yes <- bc_default_priors(has_shape_submodel = TRUE)
  expect_true(nrow(priors_yes) > nrow(priors_no))
})

test_that("bc_suggest_family auto-detects real-valued data", {
  y <- c(1.5, -0.3, 2.1, -1.0, 0.5)
  fam <- bc_suggest_family(y)
  expect_equal(fam$family, "student")
})

test_that("bc_suggest_family explicit type=real returns student", {
  y <- c(1.5, 2.3, 0.8)
  fam <- bc_suggest_family(y, type = "real")
  expect_equal(fam$family, "student")
})

test_that("bc_suggest_family explicit type=gaussian warns on counts", {
  y <- c(100, 200, 50, 300, 80)
  expect_warning(bc_suggest_family(y, type = "gaussian"), "count")
})

test_that("bc_suggest_family explicit type=gaussian warns on positive", {
  y <- c(1.5, 2.3, 0.8, 3.1, 1.2)
  expect_warning(bc_suggest_family(y, type = "gaussian"), "positive")
})

test_that("bc_default_priors adds nu prior for student family", {
  fam <- brms::student(link = "identity")
  priors <- bc_default_priors(family = fam)
  expect_true(any(priors$class == "nu"))
})

test_that("bc_simulate_benchmark generates correct structure", {
  data <- bc_simulate_benchmark(n_systems = 5, n_methods = 2)
  expect_s3_class(data, "tbl_df")
  expect_equal(nrow(data), 10)
  expect_true("system_id" %in% names(data))
  expect_true("method" %in% names(data))
  expect_true("count" %in% names(data))
  expect_true(is.factor(data$system_id))
  expect_true(is.factor(data$method))
  expect_equal(nlevels(data$method), 2)
  expect_true(all(data$count >= 0))
})

test_that("bc_simulate_benchmark generates Gamma data", {
  data <- bc_simulate_benchmark(n_systems = 5, family = "gamma")
  expect_true("time" %in% names(data))
  expect_true(all(data$time > 0))
})

test_that("bc_simulate_benchmark generates Bernoulli data", {
  data <- bc_simulate_benchmark(n_systems = 10, family = "bernoulli")
  expect_true("success" %in% names(data))
  expect_true(all(data$success %in% c(0, 1)))
})

test_that("bc_simulate_benchmark generates Student-t data", {
  data <- bc_simulate_benchmark(n_systems = 5, family = "student")
  expect_true("value" %in% names(data))
})

test_that("bc_simulate_benchmark supports censoring", {
  data <- bc_simulate_benchmark(n_systems = 20, cens_threshold = 400)
  expect_true("censored" %in% names(data))
  expect_type(data$censored, "integer")
  expect_true(all(data$count <= 400))
  # With threshold=400 and default intercept=log(500), some should be censored
  expect_true(any(data$censored == 1))
})

test_that("bc_simulate_benchmark handles 3+ methods", {
  data <- bc_simulate_benchmark(n_systems = 5, n_methods = 3,
                                true_effect = c(log(0.5), log(0.8)))
  expect_equal(nlevels(data$method), 3)
  expect_equal(nrow(data), 15)
})

test_that("bc_suggest_family errors on empty vector", {
  expect_error(bc_suggest_family(numeric(0)), "empty or all NA")
})

test_that("bc_suggest_family errors on all-NA vector", {
  expect_error(bc_suggest_family(c(NA, NA, NA)), "empty or all NA")
})

test_that("bc_suggest_family handles single value", {
  fam <- bc_suggest_family(42)
  # Single non-negative integer: detected as count

  expect_equal(fam$family, "negbinomial")
})

test_that("bc_suggest_family type='real' returns student for positive data", {
  fam <- bc_suggest_family(c(1.5, 2.3, 0.8), type = "real")
  expect_equal(fam$family, "student")
  expect_equal(fam$link, "identity")
})

test_that("bc_suggest_family type='gaussian' with positive continuous warns", {
  y <- c(1.5, 2.3, 0.8, 3.1)
  expect_warning(bc_suggest_family(y, type = "gaussian"), "positive")
})

test_that("bc_default_priors with student family includes nu prior", {
  fam <- brms::student(link = "identity")
  priors <- bc_default_priors(family = fam)
  expect_s3_class(priors, "brmsprior")
  expect_true(any(priors$class == "nu"))
})

test_that("bc_default_priors with has_spline=TRUE adds sds prior", {
  priors_no <- bc_default_priors(has_spline = FALSE)
  priors_yes <- bc_default_priors(has_spline = TRUE)
  expect_true(any(priors_yes$class == "sds"))
  expect_false(any(priors_no$class == "sds"))
})

test_that("bc_default_priors with Gamma family includes shape prior", {
  fam <- brms::brmsfamily("Gamma", link = "log")
  priors <- bc_default_priors(family = fam)
  expect_true(any(priors$class == "shape"))
})
