#' @srrstats {BS4.3} bc_check_convergence() with configurable thresholds.
#' @srrstats {BS4.5} bc_check_convergence() warns on non-convergence.
#' @srrstats {BS5.3} bc_check_convergence() returns convergence statistics.
#' @srrstats {BS5.5} bc_check_convergence()$problems returns diagnostics.
#' @srrstats {RE3.0} bc_check_convergence() warns on non-convergence.
#' @srrstats {RE3.2} Default thresholds: max_rhat=1.01, min_ess=400.
#' @srrstats {RE3.3} bc_check_convergence() allows explicit threshold setting.
#' Check convergence diagnostics for a brmsfit
#'
#' Examines Rhat and effective sample size (ESS) for all parameters and
#' returns a structured summary with pass/fail flags.
#'
#' @param model A `brmsfit` object.
#' @param max_rhat Maximum acceptable Rhat (default 1.01).
#' @param min_ess Minimum acceptable bulk ESS (default 400).
#' @return A list with components:
#'   \describe{
#'     \item{passed}{Logical. `TRUE` if all diagnostics pass.}
#'     \item{summary}{Data frame from [posterior::summarise_draws()] with
#'       rhat, ess_bulk, ess_tail per parameter.}
#'     \item{max_rhat}{Observed maximum Rhat.}
#'     \item{min_ess}{Observed minimum bulk ESS.}
#'     \item{problems}{Character vector describing any issues.}
#'   }
#' @examples
#' \dontrun{
#' model <- bc_fit(bc_simulate_benchmark(), response = "count")
#' bc_check_convergence(model)
#' }
#' @family diagnostics
#' @export
bc_check_convergence <- function(model, max_rhat = 1.01, min_ess = 400) {
  if (!inherits(model, "brmsfit")) {
    cli::cli_abort("{.arg model} must be a brmsfit object.")
  }

  summ <- posterior::summarise_draws(
    posterior::as_draws(model),
    "rhat", "ess_bulk", "ess_tail"
  )

  problems <- character(0)

  obs_max_rhat <- max(summ$rhat, na.rm = TRUE)
  obs_min_ess <- min(summ$ess_bulk, na.rm = TRUE)

  if (obs_max_rhat > max_rhat) {
    bad <- summ$variable[summ$rhat > max_rhat]
    problems <- c(problems,
      sprintf("Rhat > %.3f for: %s", max_rhat, paste(bad, collapse = ", ")))
  }

  if (obs_min_ess < min_ess) {
    bad <- summ$variable[summ$ess_bulk < min_ess]
    problems <- c(problems,
      sprintf("Bulk ESS < %d for: %s", min_ess, paste(bad, collapse = ", ")))
  }

  passed <- length(problems) == 0
  if (passed) {
    cli::cli_inform(c("v" = "All convergence diagnostics passed (Rhat <= {max_rhat}, ESS >= {min_ess})."))
  } else {
    cli::cli_warn(c("!" = "Convergence issues detected:", problems))
  }

  list(
    passed = passed,
    summary = summ,
    max_rhat = obs_max_rhat,
    min_ess = obs_min_ess,
    problems = problems
  )
}

#' Compute LOO-CV with optional reloo
#'
#' Calls the brms LOO method with Pareto-k diagnostic reporting. Optionally
#' refits for observations with high Pareto-k values.
#'
#' @param model A `brmsfit` object.
#' @param reloo Logical. If `TRUE`, refits for observations with Pareto k > 0.7
#'   (default `TRUE`).
#' @return A `loo` object with attached summary.
#' @examples
#' \dontrun{
#' model <- bc_fit(bc_simulate_benchmark(), response = "count")
#' loo_result <- bc_loo(model)
#' }
#' @family diagnostics
#' @export
bc_loo <- function(model, reloo = TRUE) {
  if (!inherits(model, "brmsfit")) {
    cli::cli_abort("{.arg model} must be a brmsfit object.")
  }

  loo_result <- loo::loo(model, save_psis = TRUE, reloo = reloo)

  pk <- loo_result$diagnostics$pareto_k
  n_bad <- sum(pk > 0.7, na.rm = TRUE)
  n_ok <- sum(pk <= 0.5, na.rm = TRUE)
  n_marginal <- sum(pk > 0.5 & pk <= 0.7, na.rm = TRUE)

  cli::cli_inform(c(
    "i" = "LOO-CV: elpd = {round(loo_result$estimates['elpd_loo', 'Estimate'], 1)}",
    "i" = "Pareto k: {n_ok} good (k <= 0.5), {n_marginal} marginal, {n_bad} bad (k > 0.7)"
  ))

  loo_result
}

#' Run posterior predictive check suite
#'
#' Generates a set of posterior predictive check plots for visual model
#' assessment.
#'
#' @param model A `brmsfit` object.
#' @param group_col Column name for grouped checks (default `"method"`).
#' @param ndraws Number of posterior draws for density overlay (default 50).
#' @return A named list of ggplot objects.
#' @examples
#' \dontrun{
#' model <- bc_fit(bc_simulate_benchmark(), response = "count")
#' plots <- bc_pp_check(model)
#' }
#' @family diagnostics
#' @export
bc_pp_check <- function(model, group_col = "method", ndraws = 50) {
  if (!inherits(model, "brmsfit")) {
    cli::cli_abort("{.arg model} must be a brmsfit object.")
  }

  plots <- list()

  plots$density <- bayesplot::pp_check(model, ndraws = ndraws)
  plots$grouped <- bayesplot::pp_check(model,
    type = "intervals_grouped",
    group = group_col
  )

  plots
}

#' Compare models via LOO-CV
#'
#' Compares two or more fitted models using approximate leave-one-out
#' cross-validation via [loo::loo_compare()].
#'
#' @param ... Two or more `brmsfit` objects, or a single named list of
#'   brmsfit objects.
#' @param model_names Optional character vector of model names. If `NULL`,
#'   uses the argument names or `"model_1"`, `"model_2"`, etc.
#' @return A tibble with columns: model, elpd_diff, se_diff.
#' @examples
#' \dontrun{
#' data <- bc_simulate_benchmark(n_systems = 20)
#' m1 <- bc_fit(data, response = "count")
#' m2 <- bc_fit(data, response = "count", model_shape = TRUE)
#' bc_loo_compare(m1, m2, model_names = c("fixed_shape", "varying_shape"))
#' }
#' @family diagnostics
#' @export
bc_loo_compare <- function(..., model_names = NULL) {
  models <- list(...)

  # Handle named list input
  if (length(models) == 1 && is.list(models[[1]]) && !inherits(models[[1]], "brmsfit")) {
    models <- models[[1]]
  }

  if (length(models) < 2) {
    cli::cli_abort("Need at least 2 models for comparison, got {length(models)}.")
  }

  for (i in seq_along(models)) {
    if (!inherits(models[[i]], "brmsfit")) {
      cli::cli_abort("Model {i} is not a brmsfit object.")
    }
  }

  # Set names
  if (!is.null(model_names)) {
    names(models) <- model_names
  } else if (is.null(names(models))) {
    names(models) <- paste0("model_", seq_along(models))
  }

  # Compute LOO for each (without reloo for speed)
  cli::cli_inform("Computing LOO-CV for {length(models)} models...")
  loo_list <- lapply(models, loo::loo)

  # Compare
  comp <- loo::loo_compare(loo_list)
  comp_df <- as.data.frame(comp)
  comp_df$model <- rownames(comp_df)

  result <- dplyr::tibble(
    model = comp_df$model,
    elpd_diff = comp_df$elpd_diff,
    se_diff = comp_df$se_diff
  )

  best <- result$model[1]
  cli::cli_inform(c("v" = "Preferred model: {.val {best}}"))

  result
}
