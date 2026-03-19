#' @srrstats {BS6.4} bc_report provides summary of convergence, effects, LOO
#' @srrstats {BS6.0} brmsfit has print method. bc_report() adds formatting.
#' @srrstats {RE4.7} bc_check_convergence() returns convergence stats.
#' @srrstats {BS1.4} bc_report triggers convergence checking as part of report.
#' Generate a complete analysis report
#'
#' Produces a formatted text summary combining convergence diagnostics,
#' effect estimates, overdispersion assessment, and LOO-CV results from
#' a fitted benchmark model. Designed to be copy-pasted into a paper
#' draft or shared with collaborators.
#'
#' @param model A `brmsfit` object from [bc_fit()] or [bc_fit_design()].
#' @param width Credible interval width (default 0.95).
#' @param loo Logical. Run LOO-CV? (default `TRUE`). Set `FALSE` to skip
#'   the expensive computation.
#' @return Invisibly returns a list with components: convergence, effects,
#'   loo_result. Prints a formatted report as a side effect.
#' @examples
#' \dontrun{
#' model <- bc_fit(bc_simulate_benchmark(), response = "count")
#' bc_report(model)
#' }
#' @family diagnostics
#' @export
bc_report <- function(model, width = 0.95, loo = TRUE) {
  if (!inherits(model, "brmsfit")) {
    cli::cli_abort("{.arg model} must be a brmsfit object.")
  }

  cli::cli_h1("bayescomp Analysis Report")

  # 1. Model info
  fam <- model$family$family
  n_obs <- nrow(model$data)
  cli::cli_inform(c(
    "i" = "Family: {fam}",
    "i" = "Observations: {n_obs}",
    "i" = "Formula: {deparse(model$formula$formula, width.cutoff = 80)}"
  ))

  # 2. Convergence
  cli::cli_h2("Convergence")
  conv <- bc_check_convergence(model)

  # 3. Effects
  cli::cli_h2("Method Effects")
  effects <- bc_summarize_effects(model, width = width)
  tbl <- bc_effect_table(model, width = width)
  for (i in seq_len(nrow(tbl))) {
    cli::cli_inform("  {tbl$Effect[i]}: {tbl$Median[i]} {tbl$`95% CrI`[i]}")
  }

  # 4. Shape (NB only)
  if (fam %in% c("negbinomial", "negbinomial2")) {
    cli::cli_h2("Overdispersion")
    .report_shape(model, model_shape = "b_shape_Intercept" %in%
                    names(posterior::as_draws_df(model)))
  }

  # 5. LOO
  loo_result <- NULL
  if (loo) {
    cli::cli_h2("LOO-CV")
    loo_result <- bc_loo(model)
  }

  cli::cli_rule()
  cli::cli_inform(c("v" = "Report complete."))

  invisible(list(
    convergence = conv,
    effects = effects,
    loo_result = loo_result
  ))
}

#' @srrstats {RE4.17} bc_report summarizes model parameters.
#' @srrstats {RE4.18} bc_effect_table provides formatted table.
#' @srrstats {BS3.0} Missing value assumptions documented in bc_validate.
#' @noRd
NULL
