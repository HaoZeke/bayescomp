#' srr_stats
#'
#' All measures of standards compliance for the bayescomp package.
#' Standards are also documented in their relevant source files.
#'
#' @srrstatsVerbose TRUE
#'
#' @srrstats {G1.0} Primary references: Goswami (2025), arXiv:2505.13621
#'   (methodology); JOSS companion paper in paper.md (software description).
#' @srrstats {G1.1} bayescomp is the first R package combining domain-specific
#'   family selection, censoring, and targets integration for benchmark
#'   comparison.
#' @srrstats {G1.2} Life cycle statement in CONTRIBUTING.md: "experimental"
#'   lifecycle badge with 2-year maintenance commitment.
#' @srrstats {G1.3} Statistical terminology defined in vignettes (getting
#'   started, model selection) and function documentation: hierarchical model,
#'   random intercept, credible interval, posterior distribution, link function,
#'   overdispersion, shape parameter, LOO-CV, Pareto-k.
#' @srrstats {G1.4} All 42 exports have complete roxygen2 documentation with
#'   param, return, examples, and family tags.
#' @srrstats {G1.4a} Internal functions (.report_shape, bc_pal_discrete)
#'   documented with keywords internal or noRd.
#' @srrstats {G1.5} Reproducible performance claims via bc_simulate_benchmark()
#'   and parameter recovery tests in test-recovery.R with fixed seeds.
#' @srrstats {G1.6} Comparison with alternatives in JOSS paper (paper.md):
#'   brms direct, tidyposterior, paired t-test, Benavoli et al.
#'
#' @srrstats {G2.0} bc_validate() checks column existence, types, factor
#'   levels, and minimum method count.
#' @srrstats {G2.0a} Documentation in bc_read_benchmark, bc_pivot_long, bc_fit
#'   specifies expected column names and types.
#' @srrstats {G2.1} bc_validate() checks numeric types for response, factor
#'   for method and system columns.
#' @srrstats {G2.1a} All param docs specify expected types (character, factor,
#'   numeric, logical, brmsfit).
#' @srrstats {G2.2} bc_validate() rejects data with fewer than 2 method levels.
#'   bc_suggest_family() rejects empty or all-NA vectors.
#' @srrstats {G2.3} Character parameters use match.arg() in bc_suggest_family
#'   (type), bc_read_benchmark (format), bc_simulate_benchmark (family).
#' @srrstats {G2.3a} match.arg() used for all character enum parameters.
#' @srrstats {G2.3b} Column name matching is case-sensitive; documented in
#'   bc_read_benchmark and bc_pivot_long.
#' @srrstats {G2.4} bc_validate() converts non-factor method/system columns
#'   with warning. bc_pivot_long() creates factors from character.
#' @srrstats {G2.4a} Not applicable: package does not convert to integer.
#' @srrstats {G2.4b} Response columns validated as numeric via is.numeric().
#' @srrstats {G2.4c} Not applicable: package does not convert to character.
#' @srrstats {G2.4d} bc_validate() converts to factor via as.factor() with
#'   cli::cli_warn().
#' @srrstats {G2.4e} Not applicable: package does not convert from factor to
#'   other types.
#' @srrstats {G2.5} bc_validate() documentation states method and system_id
#'   must be unordered factors. Warning issued on auto-conversion.
#' @srrstats {G2.6} bc_validate() checks are class-agnostic (work on
#'   data.frame, tibble, data.table).
#' @srrstats {G2.7} bc_read_benchmark() accepts CSV paths and data.frames.
#'   bc_fit() accepts any data.frame with required columns.
#' @srrstats {G2.8} bc_validate() converts all inputs to standard form
#'   (factors for categorical, numeric for response) before passing to brms.
#' @srrstats {G2.9} bc_validate() issues cli::cli_warn() on type conversions
#'   (e.g., "method is not a factor. Converting.").
#' @srrstats {G2.10} Column extraction uses [[]] and dplyr::all_of() for
#'   safe extraction regardless of tibble/data.frame semantics.
#' @srrstats {G2.11} Non-standard column classes (units, hms) would be
#'   caught by bc_validate() is.numeric() check on response columns.
#' @srrstats {G2.12} List columns not explicitly handled; would cause errors
#'   at the brms level with informative messages.
#' @srrstats {G2.13} bc_validate() checks NA in required numeric columns and
#'   reports count per column.
#' @srrstats {G2.14} bc_validate() errors on NA/NaN/Inf by default.
#' @srrstats {G2.14a} bc_validate() errors on NA with message including count.
#' @srrstats {G2.14b} bc_validate() can be called with allow_negative=TRUE
#'   to relax negativity checks while still catching NA.
#' @srrstats {G2.14c} Not applicable: package does not impute missing values.
#'   Users must handle missingness before calling bc_fit().
#' @srrstats {G2.15} NaN checked separately from NA with distinct messages.
#' @srrstats {G2.16} bc_validate() has allow_negative parameter for Student-t
#'   and Gaussian families.
#'
#' @srrstats {G3.0} Not applicable: bayescomp does not compare floating point
#'   numbers for equality. All comparisons are inequality-based.
#' @srrstats {G3.1} Not applicable: bayescomp does not perform covariance
#'   calculations. Stan/brms handles all numerical linear algebra.
#' @srrstats {G3.1a} Not applicable: see G3.1.
#'
#' @srrstats {G4.0} bc_fit() file parameter for model caching accepts paths
#'   without extension (brms auto-appends .rds). bc_epred_draws() validates
#'   .rds extension.
#'
#' @srrstats {G5.0} Tests use bc_simulate_benchmark() with known DGP
#'   properties and fixed seeds.
#' @srrstats {G5.1} bc_simulate_benchmark() is exported for users to verify
#'   test data properties and conduct their own power analyses.
#' @srrstats {G5.2} All errors use cli::cli_abort() with structured messages.
#' @srrstats {G5.2a} Each cli message has unique template text.
#' @srrstats {G5.2b} test-edge-cases.R and test-data_prep.R trigger and
#'   verify error messages for all validation failures.
#' @srrstats {G5.3} test-recovery.R verifies posterior draws contain no NA.
#'   test-simulate.R verifies simulated data has no NA/NaN/Inf.
#' @srrstats {G5.4} test-recovery.R: parameter recovery tests verify
#'   correctness against known DGP.
#' @srrstats {G5.4a} Correctness tested against simple known cases via
#'   bc_simulate_benchmark() with known true_effect.
#' @srrstats {G5.4b} Not applicable: bayescomp wraps brms (existing method).
#' @srrstats {G5.4c} Not applicable: no published benchmark tables to compare.
#' @srrstats {G5.5} Fixed seeds in test-recovery.R (seeds 42-49).
#' @srrstats {G5.6} 8 parameter recovery tests across NB, Gamma, Bernoulli,
#'   Student-t families with censoring.
#' @srrstats {G5.6a} Recovery tests use 90% credible interval as tolerance.
#' @srrstats {G5.6b} Different seeds used per family (42-49).
#' @srrstats {G5.7} Not directly applicable: algorithmic performance is
#'   determined by Stan/brms, not bayescomp.
#' @srrstats {G5.8} test-edge-cases.R covers extreme input properties.
#' @srrstats {G5.8a} Zero-length data: bc_validate() errors on empty data.
#' @srrstats {G5.8b} Unsupported types: bc_validate() errors on non-numeric
#'   response, bc_suggest_family() errors on empty/all-NA input.
#' @srrstats {G5.8c} All-NA: bc_validate() catches. All-identical: handled.
#' @srrstats {G5.8d} More systems than methods is expected (24x2). Reversed
#'   case also works correctly.
#' @srrstats {G5.9} test-recovery.R tests stochastic behaviour.
#' @srrstats {G5.9a} Adding noise to benchmark data does not change results.
#' @srrstats {G5.9b} Different seeds produce consistent results.
#' @srrstats {G5.10} Extended tests gated by skip_on_cran() and cmdstan check.
#' @srrstats {G5.11} No large external datasets needed.
#' @srrstats {G5.11a} Not applicable: no downloads needed for tests.
#' @srrstats {G5.12} test-recovery.R documents skip conditions and runtime.
#'
#' @srrstats {BS1.0} bc_default_priors() documents all prior specifications.
#' @srrstats {BS1.1} bc_fit() accepts custom brmsprior via prior parameter.
#' @srrstats {BS1.2} Prior specification in README, vignettes, function docs.
#' @srrstats {BS1.2a} README shows bc_default_priors() usage.
#' @srrstats {BS1.2b} model-selection vignette covers prior specification.
#' @srrstats {BS1.2c} bc_default_priors() has examples.
#' @srrstats {BS1.3} Computational parameters documented in bc_fit() params.
#' @srrstats {BS1.3a} brms supports previous fits as starting points via init.
#' @srrstats {BS1.3b} bc_fit() backend parameter selects cmdstanr or rstan.
#' @srrstats {BS1.4} bc_fit() diagnostics parameter controls convergence
#'   checking. Documented with examples.
#' @srrstats {BS1.5} Single convergence checker (Rhat + ESS). Standard.
#' @srrstats {BS2.1} bc_validate() ensures dimensional consistency.
#' @srrstats {BS2.1a} test-data_prep.R tests dimensional validation.
#' @srrstats {BS2.2} Prior validation delegated to brms::brm().
#' @srrstats {BS2.3} Prior parameter lengths validated by brms internally.
#' @srrstats {BS2.4} Prior dimensions validated by brms against model.
#' @srrstats {BS2.5} bc_default_priors() uses well-defined distributions.
#' @srrstats {BS2.6} Computational parameters validated by brms.
#' @srrstats {BS2.7} bc_fit() passes seed to brms::brm().
#' @srrstats {BS2.8} brms supports update() for previous fits.
#' @srrstats {BS2.9} brms uses different seeds per chain by default.
#' @srrstats {BS2.10} brms handles chain seed diagnostics.
#' @srrstats {BS2.11} Not applicable: no direct starting value interface.
#' @srrstats {BS2.12} bc_fit() diagnostics parameter controls verbosity.
#' @srrstats {BS2.13} bc_fit(diagnostics=FALSE) suppresses messages.
#' @srrstats {BS2.14} cli::cli_warn() used for recoverable warnings.
#' @srrstats {BS2.15} cli::cli_abort() throws catchable rlang conditions.
#' @srrstats {BS3.0} Missing value assumptions documented in bc_validate().
#' @srrstats {BS3.1} Collinearity delegated to brms/Stan.
#' @srrstats {BS3.2} Not applicable: see BS3.1.
#' @srrstats {BS4.0} NUTS/HMC documented via brms reference.
#' @srrstats {BS4.1} Comparison in JOSS paper.
#' @srrstats {BS4.3} bc_check_convergence() documented with configurable
#'   max_rhat and min_ess thresholds. bc_pp_check(), bc_plot_loo_pit(), and
#'   bc_dharma_check() provide posterior predictive validation.
#' @srrstats {BS4.3} bc_check_convergence() with configurable thresholds.
#' @srrstats {BS4.4} Not applicable: NUTS does not support early stopping.
#' @srrstats {BS4.5} bc_check_convergence() warns on non-convergence.
#' @srrstats {BS4.6} Not applicable: single convergence checker.
#' @srrstats {BS4.7} Convergence thresholds tested in test suite.
#' @srrstats {BS5.0} brmsfit includes seed.
#' @srrstats {BS5.1} brmsfit includes input data and formula.
#' @srrstats {BS5.2} brmsfit includes prior specification.
#' @srrstats {BS5.3} bc_check_convergence() returns convergence statistics.
#' @srrstats {BS5.4} Not applicable: single convergence checker.
#' @srrstats {BS5.5} bc_check_convergence()$problems returns diagnostics.
#' @srrstats {BS6.0} brmsfit has print method. bc_report() adds formatting.
#' @srrstats {BS6.1} brmsfit has plot method. bc_plot_* adds specialization.
#' @srrstats {BS6.2} bc_plot_trace() plots posterior sequences.
#' @srrstats {BS6.3} bc_plot_shape(), bc_plot_conditional() plot posteriors.
#' @srrstats {BS6.4} bc_report() provides summary. brms::summary() also works.
#' @srrstats {BS6.5} Not implemented: combined plots. Use patchwork.
#' @srrstats {BS7.0} test-recovery.R: 8 parameter recovery tests.
#' @srrstats {BS7.1} Not directly applicable: prior recovery needs zero data.
#' @srrstats {BS7.2} test-recovery.R: posterior recovery with known DGP.
#' @srrstats {BS7.3} Not applicable: efficiency is Stan/brms property.
#' @srrstats {BS7.4} test-recovery.R: fitted values on input scale.
#' @srrstats {BS7.4a} Scale implications tested: log-link uses exp().
#'
#' @srrstats {RE1.0} bc_fit() formula interface. bc_fit_design() for bf().
#' @srrstats {RE1.1} Formula construction documented in bc_fit().
#' @srrstats {RE1.2} Predictor types documented in bc_validate().
#' @srrstats {RE1.3} brmsfit retains input data and column names.
#' @srrstats {RE1.3a} Row names not transferred (tibbles lack row names).
#' @srrstats {RE1.4} Model assumptions documented in vignettes and docs.
#' @srrstats {RE2.0} No default transformations. bc_pivot_long() reshapes only.
#' @srrstats {RE2.1} bc_validate() handles NA/NaN/Inf with distinct messages.
#' @srrstats {RE2.2} Missing values rejected in both response and predictors.
#' @srrstats {RE2.3} Not applicable: no centering/offsetting by bayescomp.
#' @srrstats {RE2.4} Collinearity delegated to brms.
#' @srrstats {RE2.4a} Not applicable: see RE2.4.
#' @srrstats {RE2.4b} Not applicable: see RE2.4.
#' @srrstats {RE3.0} bc_check_convergence() warns on non-convergence.
#' @srrstats {RE3.1} bc_fit(diagnostics=FALSE) suppresses messages.
#' @srrstats {RE3.2} Default thresholds: max_rhat=1.01, min_ess=400.
#' @srrstats {RE3.3} bc_check_convergence() allows explicit threshold setting.
#' @srrstats {RE4.0} Returns brmsfit objects (established S3 class).
#' @srrstats {RE4.1} Not applicable: brmsfit requires fitting.
#' @srrstats {RE4.2} brmsfit supports coef() and fixef().
#' @srrstats {RE4.3} Bayesian CrI via bc_summarize_effects(), not confint().
#' @srrstats {RE4.4} brmsfit supports formula().
#' @srrstats {RE4.5} brmsfit supports nobs().
#' @srrstats {RE4.6} brms provides vcov.brmsfit().
#' @srrstats {RE4.7} bc_check_convergence() returns convergence stats.
#' @srrstats {RE4.8} brmsfit retains response via model$data.
#' @srrstats {RE4.9} brms::fitted() provides modelled values.
#' @srrstats {RE4.10} brms::residuals() provides residuals. bc_dharma_check().
#' @srrstats {RE4.11} bc_loo() provides elpd. bc_summarize_effects() gives CrI.
#' @srrstats {RE4.12} Not applicable: no user-facing transformations.
#' @srrstats {RE4.13} brmsfit retains predictor data.
#' @srrstats {RE4.14} Not applicable: not a forecasting package.
#' @srrstats {RE4.15} Not applicable: see RE4.14.
#' @srrstats {RE4.16} brms::predict() handles new factor levels.
#' @srrstats {RE4.17} brms::print.brmsfit() summarizes. bc_report() adds.
#' @srrstats {RE4.18} brms::summary.brmsfit(). bc_effect_table().
#' @srrstats {RE5.0} Not applicable: performance scaling is Stan/brms.
#' @srrstats {RE6.0} bc_plot_conditional() provides default visualization.
#' @srrstats {RE6.1} brmsfit dispatches to brms::plot.brmsfit().
#' @srrstats {RE6.2} bc_plot_conditional() shows fitted + CrI + raw data.
#' @srrstats {RE6.3} bc_plot_conditional(show_extrapolation=TRUE) distinguishes.
#' @srrstats {RE7.0} Not applicable: benchmark data is inherently noisy.
#' @srrstats {RE7.0a} Not applicable: see RE7.0.
#' @srrstats {RE7.1} Not applicable: see RE7.0.
#' @srrstats {RE7.1a} Not applicable: see RE7.0.
#' @srrstats {RE7.2} test-data_prep.R verifies names/levels retained.
#' @srrstats {RE7.3} Not directly applicable: brmsfit supports standard accessors.
#' @srrstats {RE7.4} Not applicable: no forecasting.
#'
#' @noRd
NULL
