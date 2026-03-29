#' srr_stats
#'
#' Package-level standards compliance for bayescomp.
#' Implementation-specific standards are documented in their
#' respective source files (data_prep.R, families.R, models.R, etc.).
#'
#' @srrstatsVerbose TRUE
#'
#' @srrstats {G1.0} Primary references: Goswami (2025), arXiv:2505.13621;
#'   JOSS companion paper in paper.md.
#' @srrstats {G1.1} First R package combining domain-specific family selection,
#'   censoring, and targets integration for benchmark comparison.
#' @srrstats {G1.2} Life cycle statement in CONTRIBUTING.md with 2-year
#'   maintenance commitment.
#' @srrstats {G1.3} Statistical terminology defined in vignettes and docs.
#' @srrstats {G1.4} All exports have complete roxygen2 docs.
#' @srrstats {G1.4a} Internal functions documented with keywords internal.
#' @srrstats {G1.5} Reproducible performance claims via bc_simulate_benchmark.
#' @srrstats {G1.6} Comparison with alternatives in JOSS paper.
#' @srrstatsNA {G3.1} bayescomp does not compute covariances directly;
#'   all covariance structure is handled internally by brms/Stan.
#' @srrstatsNA {G3.1a} Not applicable: no user-facing covariance methods.
#' @srrstats {G4.0} bc_fit file parameter for model caching. bc_epred_draws
#'   validates .rds extension.
#' @srrstats {G5.0} Tests use bc_simulate_benchmark with known DGP.
#' @srrstats {G5.1} bc_simulate_benchmark exported for user verification.
#' @srrstats {G5.3} test-data_prep.R: bc_validate explicitly rejects NA/NaN/
#'   Inf in return data; test-simulate.R checks output has no NA.
#' @srrstats {G5.8} Edge condition tests in test-edge-cases.R and
#'   test-data_prep.R cover zero-length, all-NA, single-method data.
#' @srrstats {BS1.5} Only one convergence checker (bc_check_convergence
#'   using Rhat + ESS); not applicable to test differences.
#' @srrstats {BS4.0} NUTS/HMC documented via brms reference.
#' @srrstats {BS4.1} Comparison in JOSS paper.
#' @srrstatsNA {BS5.4} Only one convergence checker implemented; return
#'   details of which checker used is not applicable.
#' @srrstats {RE5.0} Performance scaling is Stan/brms property.
#' @srrstatsNA {RE7.0} bayescomp wraps brms: predictions on training data
#'   are posterior draws, not point estimates; identity with fitted values
#'   is a brms/Stan property tested upstream.
#' @srrstatsNA {RE7.0a} Not applicable: see RE7.0.
#' @srrstatsNA {RE7.3} Numerical stability under extreme conditions is a
#'   property of Stan's NUTS sampler, tested upstream in brms/Stan.
#'
#' @noRd
NULL
