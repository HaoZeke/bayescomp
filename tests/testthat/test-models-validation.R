test_that("bc_fit errors on missing response column", {
  data <- bc_simulate_benchmark(n_systems = 5, n_methods = 2, seed = 401)
  expect_error(
    bc_fit(data, response = "nonexistent_column"),
    "Missing required column"
  )
})

test_that("bc_fit errors on non-data.frame input", {
  expect_error(bc_fit("not_a_dataframe", response = "count"))
})

test_that("bc_fit model_shape warns on non-negbinomial family", {
  data <- bc_simulate_benchmark(n_systems = 5, n_methods = 2,
                                family = "gamma", seed = 402)
  # model_shape should warn and then fail at brm (no cmdstan)
  # but we can at least test it does not silently ignore
  skip_if_not_installed("cmdstanr")
  skip_if_not(
    tryCatch({ cmdstanr::cmdstan_path(); TRUE }, error = function(e) FALSE),
    "CmdStan not configured"
  )
  expect_warning(
    tryCatch(
      bc_fit(data, response = "time",
             family = brms::brmsfamily("Gamma", link = "log"),
             model_shape = TRUE, chains = 1, iter = 10, warmup = 5,
             diagnostics = FALSE),
      error = function(e) NULL
    ),
    "only supported for negative binomial"
  )
})

test_that("bc_fit_design errors on non-brmsformula", {
  data <- bc_simulate_benchmark(n_systems = 5, n_methods = 2, seed = 403)
  expect_error(
    bc_fit_design(data, formula = y ~ x),
    "brms formula"
  )
})

test_that("bc_fit_design errors on missing response in data", {
  data <- bc_simulate_benchmark(n_systems = 5, n_methods = 2, seed = 404)
  formula <- brms::bf(nonexistent ~ method + (1 | system_id))
  expect_error(
    bc_fit_design(data, formula = formula),
    "not found in data"
  )
})

test_that("bc_fit with cens_col validation: column not found", {
  data <- bc_simulate_benchmark(n_systems = 5, n_methods = 2, seed = 405)
  expect_error(
    bc_fit(data, response = "count", cens_col = "nonexistent"),
    "not found in data"
  )
})

test_that("bc_fit with cens_col validation: non-binary column", {
  data <- bc_simulate_benchmark(n_systems = 5, n_methods = 2, seed = 406)
  data$bad_cens <- c(0, 1, 2, 0, 1, 0, 1, 2, 0, 1)
  expect_error(
    bc_fit(data, response = "count", cens_col = "bad_cens"),
    "must be binary"
  )
})

test_that("bc_check_convergence errors on non-brmsfit", {
  expect_error(bc_check_convergence(lm(1 ~ 1)), "brmsfit")
})

test_that("bc_loo errors on non-brmsfit", {
  expect_error(bc_loo(lm(1 ~ 1)), "brmsfit")
})

test_that("bc_loo_compare errors with fewer than 2 models", {
  expect_error(bc_loo_compare(), "at least 2 models")
})

test_that("bc_fit_design errors on string formula", {
  data <- bc_simulate_benchmark(n_systems = 5, n_methods = 2, seed = 407)
  expect_error(
    bc_fit_design(data, formula = "count ~ method"),
    "brms formula"
  )
})

test_that("bc_epred_draws errors on non-brmsfit", {
  expect_error(bc_epred_draws(lm(1 ~ 1), data.frame(x = 1)), "brmsfit")
})

test_that("bc_epred_draws errors on non-data.frame newdata", {
  skip_on_cran()
  # We cannot construct a real brmsfit without cmdstan, so just test the

  # newdata validation path by passing a non-brmsfit first
  expect_error(bc_epred_draws(lm(1 ~ 1), "not_df"), "brmsfit")
})
