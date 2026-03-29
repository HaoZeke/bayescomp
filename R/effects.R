#' @srrstats {RE4.0} Link-aware effect summaries document model assumptions
#' @srrstats {RE4.3} Bayesian CrI via bc_summarize_effects(), not confint().
#' @srrstats {RE4.11} bc_loo() provides elpd. bc_summarize_effects() gives CrI.
#' @srrstats {RE4.17} brms::print.brmsfit() summarizes. bc_report() adds.
#' @srrstats {RE4.18} brms::summary.brmsfit(). bc_effect_table().
#' @srrstats {BS6.4} bc_effect_table() formats effects for publication.
#' Summarize treatment effects on the response scale
#'
#' Extracts posterior draws for the method effect and transforms them to
#' the response scale (multiplicative factor and percentage change).
#'
#' @param model A `brmsfit` object.
#' @param width Credible interval width (default 0.95).
#' @return A tibble with columns: effect_type, median, lower, upper, formatted.
#'   For log-link models: baseline expected value, multiplicative factors,
#'   percentage changes. For logit-link: baseline probability, odds ratios.
#'   For identity-link: baseline value, additive effects.
#' @examples
#' \donttest{
#' model <- bc_fit(bc_simulate_benchmark(), response = "count")
#' bc_summarize_effects(model)
#' }
#' @family effects
#' @export
bc_summarize_effects <- function(model, width = 0.95) {
  if (!inherits(model, "brmsfit")) {
    cli::cli_abort("{.arg model} must be a brmsfit object.")
  }

  draws <- posterior::as_draws_df(model)
  alpha <- (1 - width) / 2
  link <- model$family$link

  # Find the intercept and method effect columns
  param_names <- names(draws)
  intercept_col <- grep("^b_Intercept$", param_names, value = TRUE)
  method_cols <- grep("^b_method|^b_Method", param_names, value = TRUE)

  if (length(intercept_col) == 0) {
    cli::cli_abort("No intercept found in model parameters.")
  }

  results <- list()

  if (link == "log") {
    # Log-link (negbinomial, Gamma): exponentiate for multiplicative effects
    baseline_draws <- exp(draws[[intercept_col]])
    results[[1]] <- dplyr::tibble(
      effect_type = "Expected Response (Baseline)",
      median = stats::median(baseline_draws),
      lower = stats::quantile(baseline_draws, alpha),
      upper = stats::quantile(baseline_draws, 1 - alpha)
    )

    for (col in method_cols) {
      method_name <- sub("^b_(method|Method)", "", col)
      mult_draws <- exp(draws[[col]])
      perc_draws <- (mult_draws - 1) * 100

      results[[length(results) + 1]] <- dplyr::tibble(
        effect_type = paste0("Multiplicative Factor (", method_name, ")"),
        median = stats::median(mult_draws),
        lower = stats::quantile(mult_draws, alpha),
        upper = stats::quantile(mult_draws, 1 - alpha)
      )
      results[[length(results) + 1]] <- dplyr::tibble(
        effect_type = paste0("Percentage Change (", method_name, ")"),
        median = stats::median(perc_draws),
        lower = stats::quantile(perc_draws, alpha),
        upper = stats::quantile(perc_draws, 1 - alpha)
      )
    }
  } else if (link == "logit") {
    # Logit-link (Bernoulli): odds ratios
    baseline_p <- stats::plogis(draws[[intercept_col]])
    results[[1]] <- dplyr::tibble(
      effect_type = "Baseline Probability (Reference)",
      median = stats::median(baseline_p),
      lower = stats::quantile(baseline_p, alpha),
      upper = stats::quantile(baseline_p, 1 - alpha)
    )

    for (col in method_cols) {
      method_name <- sub("^b_(method|Method)", "", col)
      or_draws <- exp(draws[[col]])

      results[[length(results) + 1]] <- dplyr::tibble(
        effect_type = paste0("Odds Ratio (", method_name, ")"),
        median = stats::median(or_draws),
        lower = stats::quantile(or_draws, alpha),
        upper = stats::quantile(or_draws, 1 - alpha)
      )
    }
  } else {
    # Identity-link (Student-t, Gaussian): raw additive effects
    baseline_draws <- draws[[intercept_col]]
    results[[1]] <- dplyr::tibble(
      effect_type = "Expected Response (Baseline)",
      median = stats::median(baseline_draws),
      lower = stats::quantile(baseline_draws, alpha),
      upper = stats::quantile(baseline_draws, 1 - alpha)
    )

    for (col in method_cols) {
      method_name <- sub("^b_(method|Method)", "", col)
      eff_draws <- draws[[col]]

      results[[length(results) + 1]] <- dplyr::tibble(
        effect_type = paste0("Additive Effect (", method_name, ")"),
        median = stats::median(eff_draws),
        lower = stats::quantile(eff_draws, alpha),
        upper = stats::quantile(eff_draws, 1 - alpha)
      )
    }
  }

  out <- dplyr::bind_rows(results)
  out$formatted <- sprintf("%.2f [%.2f, %.2f]", out$median, out$lower, out$upper)

  out
}

#' Generate a publication-ready effect summary table
#'
#' Formats the output of [bc_summarize_effects()] for inclusion in
#' manuscripts. Percentage changes are formatted with `%` signs and
#' credible intervals are in brackets.
#'
#' @param model A `brmsfit` object.
#' @param ... Arguments passed to [bc_summarize_effects()].
#' @return A data frame with columns: Effect, Median, `95% CrI`.
#' @examples
#' \donttest{
#' model <- bc_fit(bc_simulate_benchmark(), response = "count")
#' bc_effect_table(model)
#' }
#' @family effects
#' @export
bc_effect_table <- function(model, ...) {
  effects <- bc_summarize_effects(model, ...)

  dplyr::tibble(
    Effect = effects$effect_type,
    Median = ifelse(
      grepl("Percentage", effects$effect_type),
      sprintf("%.1f%%", effects$median),
      sprintf("%.2f", effects$median)
    ),
    `95% CrI` = ifelse(
      grepl("Percentage", effects$effect_type),
      sprintf("[%.1f%%, %.1f%%]", effects$lower, effects$upper),
      sprintf("[%.2f, %.2f]", effects$lower, effects$upper)
    )
  )
}

#' Pairwise method contrasts
#'
#' Computes all pairwise comparisons between method levels using posterior
#' draws. Requires the `marginaleffects` package.
#'
#' @param model A `brmsfit` object.
#' @param method_col Name of the method column (default `"method"`).
#' @param width Credible interval width (default 0.95).
#' @return A tibble with columns: contrast, estimate, lower, upper, formatted.
#' @examples
#' \donttest{
#' model <- bc_fit(bc_simulate_benchmark(), response = "count")
#' bc_pairwise_contrasts(model)
#' }
#' @family effects
#' @export
bc_pairwise_contrasts <- function(model, method_col = "method", width = 0.95) {
  if (!inherits(model, "brmsfit")) {
    cli::cli_abort("{.arg model} must be a brmsfit object.")
  }
  if (!requireNamespace("marginaleffects", quietly = TRUE)) {
    cli::cli_abort(
      "Package {.pkg marginaleffects} is required for pairwise contrasts. Install with {.code install.packages(\"marginaleffects\")}."
    )
  }

  comp <- marginaleffects::avg_comparisons(
    model,
    variables = method_col,
    conf_level = width
  )

  result <- dplyr::tibble(
    contrast = comp$contrast,
    estimate = comp$estimate,
    lower = comp$conf.low,
    upper = comp$conf.high
  )
  result$formatted <- sprintf("%.2f [%.2f, %.2f]", result$estimate,
                               result$lower, result$upper)

  result
}

#' @srrstats {RE4.2} bc_summarize_effects provides response-scale summaries.
#' @srrstats {RE4.3} Bayesian CrI via bc_summarize_effects.
#' @srrstats {RE4.17} bc_report provides summary. brms::print also works.
#' @srrstats {RE4.18} bc_effect_table provides formatted effect table.
#' @noRd
NULL
