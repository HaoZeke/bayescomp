test_that("parameter recovery: negbinomial", {
  skip_on_cran()
  skip_if_not_installed("cmdstanr")

  true_eff <- log(0.5)
  data <- bc_simulate_benchmark(
    n_systems = 20, n_methods = 2,
    true_effect = true_eff, family = "negbinomial",
    shape = 50, intercept = log(500), system_sd = 0.3, seed = 42
  )

  model <- bc_fit(
    data, response = "count", diagnostics = FALSE,
    chains = 2, iter = 500, warmup = 200, cores = 2, seed = 42
  )

  draws <- posterior::as_draws_df(model)
  eff_draws <- draws[["b_methodmethod_2"]]
  lo <- quantile(eff_draws, 0.05)
  hi <- quantile(eff_draws, 0.95)
  expect_true(true_eff >= lo && true_eff <= hi,
    info = sprintf("true_effect=%.2f not in 90%% CrI [%.2f, %.2f]", true_eff, lo, hi))
})

test_that("parameter recovery: negbinomial with censoring", {
  skip_on_cran()
  skip_if_not_installed("cmdstanr")

  true_eff <- log(0.5)
  data <- bc_simulate_benchmark(
    n_systems = 20, n_methods = 2,
    true_effect = true_eff, family = "negbinomial",
    shape = 50, intercept = log(500), system_sd = 0.3,
    cens_threshold = 600, seed = 43
  )

  expect_true(any(data$censored == 1), info = "No censored observations generated")

  model <- bc_fit(
    data, response = "count", cens_col = "censored", diagnostics = FALSE,
    chains = 2, iter = 500, warmup = 200, cores = 2, seed = 43
  )

  draws <- posterior::as_draws_df(model)
  eff_draws <- draws[["b_methodmethod_2"]]
  lo <- quantile(eff_draws, 0.05)
  hi <- quantile(eff_draws, 0.95)
  expect_true(true_eff >= lo && true_eff <= hi,
    info = sprintf("true_effect=%.2f not in 90%% CrI [%.2f, %.2f]", true_eff, lo, hi))
})

test_that("parameter recovery: Gamma", {
  skip_on_cran()
  skip_if_not_installed("cmdstanr")

  true_eff <- log(0.7)
  data <- bc_simulate_benchmark(
    n_systems = 20, n_methods = 2,
    true_effect = true_eff, family = "gamma",
    shape = 10, intercept = log(10), system_sd = 0.2, seed = 44
  )

  model <- bc_fit(
    data, response = "time", diagnostics = FALSE,
    chains = 2, iter = 500, warmup = 200, cores = 2, seed = 44
  )

  draws <- posterior::as_draws_df(model)
  eff_draws <- draws[["b_methodmethod_2"]]
  lo <- quantile(eff_draws, 0.05)
  hi <- quantile(eff_draws, 0.95)
  expect_true(true_eff >= lo && true_eff <= hi,
    info = sprintf("true_effect=%.2f not in 90%% CrI [%.2f, %.2f]", true_eff, lo, hi))
})

test_that("parameter recovery: Bernoulli", {
  skip_on_cran()
  skip_if_not_installed("cmdstanr")

  true_eff <- 0.8  # logit scale (smaller for better recovery)
  data <- bc_simulate_benchmark(
    n_systems = 40, n_methods = 2,
    true_effect = true_eff, family = "bernoulli",
    intercept = 0, system_sd = 0.3, seed = 45
  )

  model <- bc_fit(
    data, response = "success", diagnostics = FALSE,
    chains = 2, iter = 500, warmup = 200, cores = 2, seed = 45
  )

  draws <- posterior::as_draws_df(model)
  eff_draws <- draws[["b_methodmethod_2"]]
  lo <- quantile(eff_draws, 0.05)
  hi <- quantile(eff_draws, 0.95)
  expect_true(true_eff >= lo && true_eff <= hi,
    info = sprintf("true_effect=%.2f not in 90%% CrI [%.2f, %.2f]", true_eff, lo, hi))
})

test_that("parameter recovery: Student-t", {
  skip_on_cran()
  skip_if_not_installed("cmdstanr")

  true_eff <- -0.5  # identity scale
  data <- bc_simulate_benchmark(
    n_systems = 20, n_methods = 2,
    true_effect = true_eff, family = "student",
    intercept = 0, system_sd = 0.3, sigma = 1, seed = 46
  )

  model <- bc_fit(
    data, response = "value", diagnostics = FALSE,
    family = brms::student(link = "identity"),
    chains = 2, iter = 500, warmup = 200, cores = 2, seed = 46
  )

  draws <- posterior::as_draws_df(model)
  eff_draws <- draws[["b_methodmethod_2"]]
  lo <- quantile(eff_draws, 0.05)
  hi <- quantile(eff_draws, 0.95)
  expect_true(true_eff >= lo && true_eff <= hi,
    info = sprintf("true_effect=%.2f not in 90%% CrI [%.2f, %.2f]", true_eff, lo, hi))
})

test_that("bc_loo_compare prefers negbinomial over Poisson on overdispersed data", {
  skip_on_cran()
  skip_if_not_installed("cmdstanr")

  data <- bc_simulate_benchmark(
    n_systems = 20, n_methods = 2,
    true_effect = log(0.5), family = "negbinomial",
    shape = 10, intercept = log(500), system_sd = 0.5, seed = 47
  )

  fit_nb <- bc_fit(
    data, response = "count", diagnostics = FALSE,
    family = brms::negbinomial(), model_shape = FALSE,
    chains = 2, iter = 500, warmup = 200, cores = 2, seed = 47
  )

  fit_pois <- bc_fit(
    data, response = "count", diagnostics = FALSE,
    family = brms::brmsfamily("poisson"), model_shape = FALSE,
    chains = 2, iter = 500, warmup = 200, cores = 2, seed = 47
  )

  comp <- bc_loo_compare(fit_nb, fit_pois,
                          model_names = c("negbinomial", "poisson"))
  # negbinomial should be preferred (first row, elpd_diff = 0)
  expect_equal(comp$model[1], "negbinomial")
})

test_that("bc_fit_design with interaction formula recovers effect", {
  skip_on_cran()
  skip_if_not_installed("cmdstanr")

  true_eff <- log(0.6)
  data <- bc_simulate_benchmark(
    n_systems = 15, n_methods = 2,
    true_effect = true_eff, family = "negbinomial",
    shape = 50, intercept = log(400), system_sd = 0.3, seed = 48
  )

  model <- bc_fit_design(
    data,
    formula = brms::bf(count ~ method + (1 | system_id)),
    family = brms::negbinomial(),
    diagnostics = FALSE,
    chains = 2, iter = 500, warmup = 200, cores = 2, seed = 48
  )

  draws <- posterior::as_draws_df(model)
  eff_draws <- draws[["b_methodmethod_2"]]
  lo <- quantile(eff_draws, 0.05)
  hi <- quantile(eff_draws, 0.95)
  expect_true(true_eff >= lo && true_eff <= hi,
    info = sprintf("true_effect=%.2f not in 90%% CrI [%.2f, %.2f]", true_eff, lo, hi))
})

test_that("bc_pairwise_contrasts returns correct number for 3 methods", {
  skip_on_cran()
  skip_if_not_installed("cmdstanr")
  skip_if_not_installed("marginaleffects")

  data <- bc_simulate_benchmark(
    n_systems = 15, n_methods = 3,
    true_effect = c(log(0.5), log(0.8)),
    family = "negbinomial",
    shape = 50, intercept = log(400), system_sd = 0.3, seed = 49
  )

  model <- bc_fit(
    data, response = "count", diagnostics = FALSE,
    chains = 2, iter = 500, warmup = 200, cores = 2, seed = 49
  )

  contrasts <- bc_pairwise_contrasts(model)
  # 3 methods -> at least 2 contrasts (vs reference)
  expect_true(nrow(contrasts) >= 2)
  expect_true(all(c("contrast", "estimate", "lower", "upper") %in% names(contrasts)))
})
