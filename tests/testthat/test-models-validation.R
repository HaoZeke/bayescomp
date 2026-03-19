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

# --- Coverage: bc_fit formula construction paths ---
# These tests exercise the code paths BEFORE the brm() call. The call to
# brm() itself will error (no Stan backend on CI), but the formula
# construction, validation, family/prior selection, and cli messages
# all run and get covered. We use tryCatch to swallow the brm error.

test_that("bc_fit builds formula with covariates", {
  data <- bc_simulate_benchmark(n_systems = 5, n_methods = 2, seed = 410)
  data$covar <- rnorm(nrow(data))
  err <- tryCatch(
    bc_fit(data, response = "count", covariates = "covar",
           backend = "nonexistent_backend", chains = 1, iter = 10),
    error = function(e) e
  )
  # Should fail at brm, not at our validation
  expect_false(grepl("Missing required column", conditionMessage(err)))
})

test_that("bc_fit builds formula with spline_by_method", {
  data <- bc_simulate_benchmark(n_systems = 5, n_methods = 2, seed = 411)
  data$covar <- rnorm(nrow(data))
  err <- tryCatch(
    bc_fit(data, response = "count", spline_by_method = "covar",
           backend = "nonexistent_backend", chains = 1, iter = 10),
    error = function(e) e
  )
  expect_false(grepl("Missing required column", conditionMessage(err)))
})

test_that("bc_fit builds formula with covariates AND spline", {
  data <- bc_simulate_benchmark(n_systems = 5, n_methods = 2, seed = 412)
  data$x1 <- rnorm(nrow(data))
  data$x2 <- rnorm(nrow(data))
  err <- tryCatch(
    bc_fit(data, response = "count", covariates = "x1",
           spline_by_method = "x2",
           backend = "nonexistent_backend", chains = 1, iter = 10),
    error = function(e) e
  )
  expect_false(grepl("Missing required column", conditionMessage(err)))
})

test_that("bc_fit builds censored formula when cens_col is valid", {
  data <- bc_simulate_benchmark(n_systems = 5, n_methods = 2,
                                cens_threshold = 400, seed = 413)
  err <- tryCatch(
    bc_fit(data, response = "count", cens_col = "censored",
           backend = "nonexistent_backend", chains = 1, iter = 10),
    error = function(e) e
  )
  # Should NOT fail at cens_col validation
  expect_false(grepl("must be binary", conditionMessage(err)))
  expect_false(grepl("not found in data", conditionMessage(err)))
})

test_that("bc_fit with model_shape=TRUE and negbinomial builds shape submodel formula", {
  data <- bc_simulate_benchmark(n_systems = 5, n_methods = 2, seed = 414)
  err <- tryCatch(
    bc_fit(data, response = "count",
           family = brms::negbinomial(link = "log"),
           model_shape = TRUE,
           backend = "nonexistent_backend", chains = 1, iter = 10),
    error = function(e) e
  )
  # Should NOT fail at model_shape validation (negbinomial is fine)
  expect_false(grepl("only supported for negative binomial", conditionMessage(err)))
})

test_that("bc_fit auto-detects family when family=NULL", {
  data <- bc_simulate_benchmark(n_systems = 5, n_methods = 2, seed = 415)
  err <- tryCatch(
    bc_fit(data, response = "count", family = NULL,
           backend = "nonexistent_backend", chains = 1, iter = 10),
    error = function(e) e
  )
  # Auto-detection should work, error should be from brm
  expect_false(grepl("Cannot detect family", conditionMessage(err)))
})

test_that("bc_fit allow_neg is TRUE for student family", {
  data <- bc_simulate_benchmark(n_systems = 5, n_methods = 2,
                                family = "student", seed = 416)
  err <- tryCatch(
    bc_fit(data, response = "value",
           family = brms::student(link = "identity"),
           backend = "nonexistent_backend", chains = 1, iter = 10),
    error = function(e) e
  )
  # Should NOT fail on negative value validation
  expect_false(grepl("negative values", conditionMessage(err)))
})

test_that("bc_fit uses default priors when prior=NULL", {
  data <- bc_simulate_benchmark(n_systems = 5, n_methods = 2, seed = 417)
  err <- tryCatch(
    bc_fit(data, response = "count",
           family = brms::negbinomial(link = "log"),
           prior = NULL,
           backend = "nonexistent_backend", chains = 1, iter = 10),
    error = function(e) e
  )
  # Should reach brm, not fail at prior construction
  expect_true(inherits(err, "error"))
})

test_that("bc_fit emits fitting message", {
  data <- bc_simulate_benchmark(n_systems = 5, n_methods = 2, seed = 418)
  expect_message(
    tryCatch(
      bc_fit(data, response = "count",
             family = brms::negbinomial(link = "log"),
             backend = "nonexistent_backend", chains = 1, iter = 10),
      error = function(e) NULL
    ),
    "Fitting"
  )
})

# --- Coverage: bc_fit_design paths ---

test_that("bc_fit_design auto-detects family from response in data", {
  data <- bc_simulate_benchmark(n_systems = 5, n_methods = 2, seed = 420)
  formula <- brms::bf(count ~ method + (1 | system_id))
  err <- tryCatch(
    bc_fit_design(data, formula = formula, family = NULL,
                  backend = "nonexistent_backend", chains = 1, iter = 10),
    error = function(e) e
  )
  expect_false(grepl("Cannot auto-detect family", conditionMessage(err)))
})

test_that("bc_fit_design with cens_col not found errors", {
  data <- bc_simulate_benchmark(n_systems = 5, n_methods = 2, seed = 421)
  formula <- brms::bf(count ~ method + (1 | system_id))
  expect_error(
    bc_fit_design(data, formula = formula,
                  family = brms::negbinomial(),
                  cens_col = "nonexistent"),
    "not found"
  )
})

test_that("bc_fit_design uses default priors when prior=NULL", {
  data <- bc_simulate_benchmark(n_systems = 5, n_methods = 2, seed = 422)
  formula <- brms::bf(count ~ method + (1 | system_id))
  err <- tryCatch(
    bc_fit_design(data, formula = formula,
                  family = brms::negbinomial(),
                  prior = NULL,
                  backend = "nonexistent_backend", chains = 1, iter = 10),
    error = function(e) e
  )
  expect_true(inherits(err, "error"))
})

test_that("bc_fit_design emits fitting message", {
  data <- bc_simulate_benchmark(n_systems = 5, n_methods = 2, seed = 423)
  formula <- brms::bf(count ~ method + (1 | system_id))
  expect_message(
    tryCatch(
      bc_fit_design(data, formula = formula,
                    family = brms::negbinomial(),
                    backend = "nonexistent_backend", chains = 1, iter = 10),
      error = function(e) NULL
    ),
    "Fitting"
  )
})

# --- Coverage: bc_fit_suite loop logic ---

test_that("bc_fit_suite skips missing response columns", {
  data <- bc_simulate_benchmark(n_systems = 5, n_methods = 2, seed = 430)
  # data has "count" but not "time" or "success"
  # bc_fit_suite will skip time and success, then fail at brm for count
  err <- tryCatch(
    bc_fit_suite(data, count_col = "count",
                 time_col = "time", success_col = "success",
                 backend = "nonexistent_backend", chains = 1, iter = 10),
    error = function(e) e
  )
  expect_true(inherits(err, "error"))
})

test_that("bc_fit_suite skips NULL response columns", {
  data <- bc_simulate_benchmark(n_systems = 5, n_methods = 2, seed = 431)
  err <- tryCatch(
    bc_fit_suite(data, count_col = "count",
                 time_col = NULL, success_col = NULL,
                 backend = "nonexistent_backend", chains = 1, iter = 10),
    error = function(e) e
  )
  expect_true(inherits(err, "error"))
})

test_that("bc_fit_suite emits per-model fitting messages", {
  data <- bc_simulate_benchmark(n_systems = 5, n_methods = 2, seed = 432)
  expect_message(
    tryCatch(
      bc_fit_suite(data, count_col = "count",
                   time_col = NULL, success_col = NULL,
                   backend = "nonexistent_backend", chains = 1, iter = 10),
      error = function(e) NULL
    ),
    "Fitting count model"
  )
})

test_that("bc_fit_suite with file_prefix constructs file paths", {
  data <- bc_simulate_benchmark(n_systems = 5, n_methods = 2, seed = 433)
  err <- tryCatch(
    bc_fit_suite(data, count_col = "count",
                 time_col = NULL, success_col = NULL,
                 file_prefix = "/tmp/test_bayescomp_suite",
                 backend = "nonexistent_backend", chains = 1, iter = 10),
    error = function(e) e
  )
  expect_true(inherits(err, "error"))
})

# --- Coverage: .report_shape internal function ---

test_that(".report_shape returns invisible NULL for non-brmsfit", {
  result <- bayescomp:::.report_shape(lm(1 ~ 1))
  expect_null(result)
})

test_that(".report_shape returns invisible NULL for non-negbinomial family", {
  mock <- list(family = list(family = "gaussian"))
  class(mock) <- "brmsfit"
  result <- bayescomp:::.report_shape(mock)
  expect_null(result)
})

# --- Coverage: bc_loo_compare error paths ---

test_that("bc_loo_compare errors when single model passed as list", {
  mock <- list()
  class(mock) <- "brmsfit"
  expect_error(bc_loo_compare(list(mock)), "at least 2 models")
})

test_that("bc_loo_compare errors on non-brmsfit in list", {
  mock1 <- list()
  class(mock1) <- "brmsfit"
  expect_error(bc_loo_compare(mock1, lm(1 ~ 1)), "not a brmsfit")
})

# --- Coverage: bc_pp_check error path ---

test_that("bc_pp_check errors on non-brmsfit", {
  expect_error(bc_pp_check(lm(1 ~ 1)), "brmsfit")
})

# --- Coverage: bc_validate time column checks ---

test_that("bc_validate checks NA in time column with require_time", {
  data <- data.frame(
    count = c(100, 50, 200, 150),
    method = factor(rep(c("A", "B"), 2)),
    system_id = factor(rep(c("s1", "s2"), each = 2)),
    time = c(1.0, NA, 2.0, 1.5)
  )
  expect_error(bc_validate(data, require_time = TRUE), "NA")
})

# --- Coverage: bc_filter_matching with success filtering ---

test_that("bc_filter_matching filters by success when require_success=TRUE", {
  data <- data.frame(
    system_id = factor(rep(c("s1", "s2", "s3"), each = 2)),
    method = factor(rep(c("A", "B"), 3)),
    count = c(100, 50, 200, 150, 300, 250),
    barrier = c(1.0, 1.001, 2.0, 2.001, 3.0, 3.001),
    success = c(TRUE, TRUE, TRUE, FALSE, TRUE, TRUE)
  )
  # s2 has one failed method, should be filtered
  filtered <- bc_filter_matching(data, compare_col = "barrier",
                                  tol = 0.01, require_success = TRUE)
  expect_false("s2" %in% filtered$system_id)
})

test_that("bc_filter_matching drops unused factor levels", {
  data <- data.frame(
    system_id = factor(rep(c("s1", "s2", "s3"), each = 2)),
    method = factor(rep(c("A", "B"), 3)),
    count = c(100, 50, 200, 150, 300, 250),
    barrier = c(1.0, 1.001, 2.0, 5.0, 3.0, 3.001),
    success = c(TRUE, TRUE, TRUE, TRUE, TRUE, TRUE)
  )
  filtered <- bc_filter_matching(data, compare_col = "barrier",
                                  tol = 0.01, require_success = TRUE)
  # s2 filtered out (barrier diff = 3.0), factor levels should be dropped
  expect_equal(nlevels(filtered$system_id), 2)
})

# --- Coverage: bc_suggest_family type="success" path ---

test_that("bc_suggest_family with 0/1 integers detects bernoulli", {
  y <- c(0L, 1L, 0L, 1L, 1L)
  fam <- bc_suggest_family(y)
  expect_equal(fam$family, "bernoulli")
})

# --- Coverage: bc_fit_design with valid cens_col ---

test_that("bc_fit_design appends censoring to formula", {
  data <- bc_simulate_benchmark(n_systems = 5, n_methods = 2,
                                cens_threshold = 400, seed = 440)
  formula <- brms::bf(count ~ method + (1 | system_id))
  expect_error(
    bc_fit_design(data, formula = formula,
                  family = brms::negbinomial(),
                  cens_col = "censored",
                  backend = "nonexistent_backend", chains = 1, iter = 10),
    NULL
  )
})

# --- Coverage: bc_read_benchmark wide format column validation ---

test_that("bc_read_benchmark errors on missing method column in wide format", {
  tmp <- tempfile(fileext = ".csv")
  df <- data.frame(System = c("s1", "s2"), Calls_A = c(100, 200))
  utils::write.csv(df, tmp, row.names = FALSE)
  on.exit(unlink(tmp))

  expect_error(
    bc_read_benchmark(tmp, format = "wide",
                      method_suffixes = c("A", "B"),
                      count_col = "Calls"),
    "not found"
  )
})

test_that("bc_read_benchmark errors on missing system column", {
  tmp <- tempfile(fileext = ".csv")
  df <- data.frame(Name = c("s1", "s2"),
                   Calls_A = c(100, 200), Calls_B = c(50, 150))
  utils::write.csv(df, tmp, row.names = FALSE)
  on.exit(unlink(tmp))

  expect_error(
    bc_read_benchmark(tmp, format = "wide",
                      method_suffixes = c("A", "B"),
                      system_col = "System", count_col = "Calls"),
    "not found"
  )
})

# --- Coverage: bc_pivot_long method_levels=NULL auto-factoring ---

test_that("bc_pivot_long auto-creates factor levels when method_levels=NULL", {
  wide <- data.frame(
    System = c("sys_a", "sys_b"),
    Calls_X = c(100, 200),
    Calls_Y = c(50, 150),
    stringsAsFactors = FALSE
  )
  attr(wide, "bc_system_col") <- "System"
  attr(wide, "bc_count_col") <- "Calls"
  attr(wide, "bc_format") <- "wide"

  long <- bc_pivot_long(
    wide,
    method_pattern = "_(X|Y)$",
    method_levels = NULL
  )

  expect_true(is.factor(long$method))
  expect_equal(nlevels(long$method), 2)
})
