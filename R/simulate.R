#' @srrstats {BS7.0} bc_simulate_benchmark enables parameter recovery testing
#' @srrstats {BS7.2} test-recovery.R: posterior recovery with known DGP.
#' @srrstats {G5.0} Tests use bc_simulate_benchmark() with known DGP
#'   properties and fixed seeds.
#' @srrstats {G5.1} bc_simulate_benchmark() is exported for users to verify
#'   test data properties and conduct their own power analyses.
#' @srrstats {G1.5} Reproducible performance claims via bc_simulate_benchmark()
#'   and parameter recovery tests in test-recovery.R with fixed seeds.
#' @srrstats {G5.5} Fixed seeds in test-recovery.R (seeds 42-49).
#' Simulate benchmark comparison data
#'
#' Generates synthetic benchmark data from a known data-generating process
#' for power analysis and parameter recovery testing. Produces long-format
#' data matching bayescomp conventions.
#'
#' @param n_systems Number of test systems (default 20).
#' @param n_methods Number of methods (default 2). Methods are named
#'   `"method_1"`, `"method_2"`, etc. The first method is the reference.
#' @param true_effect True log-scale effect of non-reference methods relative
#'   to the reference. For negbinomial/Gamma, this is on the log scale
#'   (e.g., `log(0.5)` means 50% reduction). For Bernoulli, on the logit
#'   scale. Scalar (same for all non-reference methods) or vector of length
#'   `n_methods - 1`.
#' @param family One of `"negbinomial"`, `"gamma"`, `"bernoulli"`, `"student"`.
#' @param shape Shape parameter for negbinomial or Gamma (default 50).
#' @param intercept Intercept on the link scale (default `log(500)` for
#'   negbinomial/Gamma, `0` for Bernoulli/Student-t).
#' @param system_sd Standard deviation of the random intercept per system
#'   (default 0.3 on the link scale).
#' @param sigma Residual SD for Student-t family (default 1).
#' @param cens_threshold Right-censoring threshold. If not `NULL`, observations
#'   above this value are censored and a `censored` column (0/1) is added.
#' @param seed Random seed for reproducibility.
#' @return A tibble with columns: `system_id` (factor), `method` (factor),
#'   and the response column named `count` (negbinomial), `time` (Gamma),
#'   `success` (Bernoulli), or `value` (Student-t). If `cens_threshold` is
#'   set, also includes `censored` (integer 0/1).
#' @examples
#' data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2)
#' head(data)
#' str(data)
#' @export
bc_simulate_benchmark <- function(n_systems = 20,
                                  n_methods = 2,
                                  true_effect = log(0.5),
                                  family = c("negbinomial", "gamma",
                                             "bernoulli", "student"),
                                  shape = 50,
                                  intercept = NULL,
                                  system_sd = 0.3,
                                  sigma = 1,
                                  cens_threshold = NULL,
                                  seed = 42) {
  family <- match.arg(family)
  set.seed(seed)

  if (length(true_effect) == 1 && n_methods > 2) {
    true_effect <- rep(true_effect, n_methods - 1)
  }

  if (is.null(intercept)) {
    intercept <- switch(family,
      negbinomial = log(500),
      gamma = log(10),
      bernoulli = 0,
      student = 0
    )
  }

  # Generate design
  system_ids <- paste0("sys_", sprintf("%02d", seq_len(n_systems)))
  method_names <- paste0("method_", seq_len(n_methods))
  grid <- expand.grid(
    system_id = system_ids,
    method = method_names,
    stringsAsFactors = FALSE
  )

  # Random intercepts
  re <- stats::rnorm(n_systems, mean = 0, sd = system_sd)
  names(re) <- system_ids

  # Method effects (reference = 0)
  effects <- c(0, true_effect)
  names(effects) <- method_names

  # Linear predictor
  eta <- intercept + re[grid$system_id] + effects[grid$method]

  # Draw responses
  response <- switch(family,
    negbinomial = {
      mu <- exp(eta)
      stats::rnbinom(nrow(grid), mu = mu, size = shape)
    },
    gamma = {
      mu <- exp(eta)
      stats::rgamma(nrow(grid), shape = shape, rate = shape / mu)
    },
    bernoulli = {
      p <- stats::plogis(eta)
      stats::rbinom(nrow(grid), size = 1, prob = p)
    },
    student = {
      mu <- eta
      mu + sigma * stats::rt(nrow(grid), df = 5)
    }
  )

  # Response column name
  resp_name <- switch(family,
    negbinomial = "count",
    gamma = "time",
    bernoulli = "success",
    student = "value"
  )

  result <- dplyr::tibble(
    system_id = factor(grid$system_id),
    method = factor(grid$method, levels = method_names),
    !!resp_name := response
  )

  # Censoring
  if (!is.null(cens_threshold) && family %in% c("negbinomial", "gamma")) {
    result[["censored"]] <- as.integer(result[[resp_name]] >= cens_threshold)
    result[[resp_name]] <- pmin(result[[resp_name]], cens_threshold)
  }

  result
}

#' @srrstats {G5.4} test-recovery.R: parameter recovery against known DGP.
#' @srrstats {G5.4a} Correctness tested against simple known cases.
#' @srrstatsNA {G5.4b} No prior implementations of bayescomp methodology
#'   exist; correctness verified via parameter recovery instead.
#' @srrstatsNA {G5.4c} No published paper outputs for direct comparison;
#'   correctness validated via simulated data with known true effects.
#' @srrstats {G5.5} Fixed seeds in test-recovery.R.
#' @srrstats {G5.6} 8 parameter recovery tests across families.
#' @srrstats {G5.6a} Recovery tests use 90% CrI as tolerance.
#' @srrstats {G5.6b} Different seeds per family (42-49).
#' @srrstats {G5.7} test-recovery.R: recovery within CrI demonstrates
#'   correct convergence behaviour as function of data properties.
#' @srrstats {BS7.0} test-recovery.R: 8 parameter recovery tests.
#' @srrstats {BS7.1} Prior recovery: with n_systems=0 or flat likelihood,
#'   brms recovers prior distribution (tested upstream in brms).
#' @srrstats {BS7.2} Posterior recovery with known DGP verified.
#' @srrstats {BS7.3} test-recovery.R demonstrates efficiency across 4
#'   families; recovery succeeds with n=20 systems, 500 iterations.
#' @srrstats {BS7.4} Fitted values on same scale as inputs.
#' @srrstats {BS7.4a} test-recovery.R tests with different intercept
#'   values (log(500) for NB, log(10) for Gamma) to verify scale.
#' @srrstats {G5.9} test-recovery.R tests stochastic behaviour.
#' @srrstats {G5.10} Extended tests gated by skip_on_cran.
#' @srrstats {G5.12} test-recovery.R documents skip conditions.
#' @noRd
NULL
