#' @srrstats {BS7.0} bc_simulate_benchmark enables parameter recovery testing
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
