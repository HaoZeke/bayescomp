#' srr_stats
#'
#' All measures of standards compliance for the bayescomp package are
#' documented here.
#'
#' @srrstatsVerbose TRUE
#'
#' @srrstats {G1.0} *Statistical Software should list at least one primary
#'   reference from published academic literature.* Primary references:
#'   Goswami (2025), arXiv:2505.13621 (methodology); JOSS companion paper
#'   in paper.md (software description).
#'
#' @srrstats {G1.1} *Statistical Software should document whether the
#'   algorithm(s) it implements are the first combined in a single package.*
#'   bayescomp is the first R package to provide a domain-specific workflow for
#'   Bayesian hierarchical comparison of computational method benchmarks,
#'   combining family auto-detection, censoring support, and targets integration.
#'
#' @srrstats {G1.4} *Software should use roxygen to document all objects.*
#'   All exported functions have complete roxygen documentation including
#'   @param, @return, and @examples.
#'
#' @srrstats {G2.0} *Implement assertions on lengths of inputs.* bc_validate()
#'   checks column existence, types, factor levels, and minimum method count.
#'
#' @srrstats {G2.1} *Implement assertions on types of inputs.* bc_validate()
#'   checks numeric types for response columns, factor types for method and
#'   system columns.
#'
#' @srrstats {G2.7} *Software should accept tabular inputs in any standard
#'   form.* bc_read_benchmark() accepts CSV paths and data.frames. bc_fit()
#'   accepts any data.frame with the required columns.
#'
#' @srrstats {G2.13} *Statistical Software should implement appropriate checks
#'   for missing data.* bc_validate() checks all required numeric columns for
#'   NA values and reports the count per column.
#'
#' @srrstats {G2.14} *Statistical Software should provide options for NaN.*
#'   bc_validate() checks for NaN separately from NA with informative messages.
#'
#' @srrstats {G2.15} *Statistical Software should provide options for Inf.*
#'   bc_validate() checks for Inf with informative messages.
#'
#' @srrstats {G2.16} *Statistical Software should provide options for negative
#'   values.* bc_validate() has allow_negative parameter, set TRUE for
#'   Student-t/Gaussian families.
#'
#' @srrstats {G5.2} *Appropriate error and warning behaviour should be
#'   demonstrated.* All input validation uses cli::cli_abort() with structured
#'   error messages. Family selection uses cli::cli_inform() for guidance.
#'
#' @srrstats {G5.4} *Correctness tests with fixed seeds.* test-recovery.R uses
#'   bc_simulate_benchmark() with fixed seeds for parameter recovery.
#'
#' @srrstats {G5.5} *Correctness tests should run to fixed tolerances.*
#'   Parameter recovery tests verify true effect within 90% CrI.
#'
#' @srrstats {BS1.0} *Bayesian software should clearly document prior
#'   distributions.* bc_default_priors() documents all 6 prior specifications
#'   with roxygen documentation. See bc_default_priors() and the JOSS
#'   companion paper (paper.md) for rationale.
#'
#' @srrstats {BS1.1} *Bayesian software should implement functionality to
#'   allow users to specify their own prior distributions.* bc_fit() and
#'   bc_fit_design() accept custom brmsprior objects via the prior parameter.
#'
#' @srrstats {BS2.0} *Bayesian software should implement at least one
#'   convergence checker.* bc_check_convergence() checks Rhat and ESS with
#'   configurable thresholds.
#'
#' @srrstats {BS2.7} *Bayesian software should enable explicit control of
#'   random seeds.* bc_fit() and bc_fit_design() pass seed to brms::brm().
#'   bc_simulate_benchmark() accepts seed parameter.
#'
#' @srrstats {BS4.2} *Bayesian software should implement at least one
#'   posterior validation method.* bc_pp_check(), bc_plot_loo_pit(), and
#'   bc_dharma_check() provide posterior predictive validation.
#'
#' @srrstats {BS4.3} *Bayesian software should document convergence
#'   checkers.* bc_check_convergence() is documented with configurable
#'   max_rhat and min_ess thresholds.
#'
#' @srrstats {BS7.0} *Bayesian software should include tests that
#'   demonstrate ability to recover parameters.* test-recovery.R includes
#'   8 parameter recovery tests across NB, Gamma, Bernoulli, Student-t
#'   families with censoring variants.
#'
#' @srrstats {RE1.0} *Regression software should document what types of
#'   data the software is designed for.* Package documentation and vignettes
#'   specify the (system x method) crossed design pattern.
#'
#' @srrstats {RE2.0} *Regression software should allow different types of
#'   input data.* bc_read_benchmark() accepts CSV and data.frames in wide
#'   or long format.
#'
#' @srrstats {RE4.0} *Regression software should document assumptions of
#'   the model.* The JOSS companion paper (paper.md) and vignettes document
#'   distributional assumptions, link functions, and random effect structure.
#'
#' @noRd
NULL
