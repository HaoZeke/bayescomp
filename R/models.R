#' @srrstats {BS2.7} bc_fit passes seed parameter to brms::brm
#' @srrstats {RE1.0} bc_fit() formula interface. bc_fit_design() for bf().
#' @srrstats {RE1.1} Formula construction documented in bc_fit().
#' @srrstats {BS1.3} Computational parameters documented in bc_fit() params.
#' @srrstats {BS1.4} bc_fit() diagnostics parameter controls convergence
#'   checking.
#' @srrstats {BS2.6} Computational parameters validated by brms.
#' @srrstats {BS2.12} bc_fit() diagnostics parameter controls verbosity.
#' @srrstats {BS2.13} bc_fit(diagnostics=FALSE) suppresses messages.
#' Fit a Bayesian benchmark comparison model
#'
#' Wraps [brms::brm()] with sensible defaults for comparing computational
#' methods on shared benchmark problems. Constructs the formula from column
#' names and optional covariates, selects the family if not provided, and
#' uses weakly informative priors by default.
#'
#' @param data Long-format benchmark data (as from [bc_pivot_long()]).
#' @param response Name of the response variable (default `"count"`).
#' @param method_col Name of the method column (default `"method"`).
#' @param system_col Name of the system/grouping column (default `"system_id"`).
#' @param covariates Character vector of covariate names for fixed effects
#'   (optional).
#' @param spline_by_method Name of a covariate for a method-varying thin plate
#'   spline (optional). Adds `s(covariate, by = method, k = 3)`.
#' @param family A brms family object. If `NULL`, auto-detected via
#'   [bc_suggest_family()].
#' @param prior A `brmsprior` object. If `NULL`, uses [bc_default_priors()].
#' @param model_shape Logical. If `TRUE`, models the dispersion parameter as
#'   a function of method (relevant for negative binomial).
#' @param chains Number of MCMC chains (default 4).
#' @param iter Total iterations per chain (default 4000).
#' @param warmup Warmup iterations per chain (default 1000).
#' @param cores Number of cores for parallel chains (default 4).
#' @param seed Random seed for reproducibility.
#' @param backend Stan backend (default `"cmdstanr"`).
#' @param file Cache file path for the fitted model (optional).
#' @param cens_col Name of a binary censoring column (0 = observed,
#'   1 = right-censored). If provided, adds `| cens(cens_col)` to the
#'   brms formula. Use with [bc_pivot_long()] `cens_value` parameter.
#' @param diagnostics Logical. If `TRUE` (default), runs convergence
#'   diagnostics after fitting and reports shape parameter for negbinomial.
#' @param adapt_delta Target acceptance rate (default 0.99).
#' @param max_treedepth Maximum tree depth (default 12).
#' @param ... Additional arguments passed to [brms::brm()].
#' @return A `brmsfit` object.
#' @examples
#' \donttest{
#' data <- bc_simulate_benchmark(n_systems = 20)
#' model <- bc_fit(data, response = "count")
#' }
#' @family fitting
#' @export
bc_fit <- function(data,
                   response = "count",
                   method_col = "method",
                   system_col = "system_id",
                   covariates = NULL,
                   spline_by_method = NULL,
                   family = NULL,
                   prior = NULL,
                   model_shape = FALSE,
                   cens_col = NULL,
                   diagnostics = TRUE,
                   chains = 4,
                   iter = 4000,
                   warmup = 1000,
                   cores = 4,
                   seed = 1995,
                   backend = NULL,
                   file = NULL,
                   adapt_delta = 0.99,
                   max_treedepth = 12,
                   ...) {

  # Auto-detect backend
  if (is.null(backend)) {
    if (nzchar(system.file(package = "cmdstanr"))) {
      backend <- "cmdstanr"
    } else {
      backend <- "rstan"
      cli::cli_inform("cmdstanr not found, falling back to rstan backend.")
    }
  }

  # Determine if negatives should be allowed based on family
  allow_neg <- FALSE
  if (!is.null(family) && family$family %in% c("student", "gaussian")) {
    allow_neg <- TRUE
  }
  bc_validate(data, count_col = response, method_col = method_col,
              system_col = system_col, allow_negative = allow_neg)

  # Validate censoring column if provided
  if (!is.null(cens_col)) {
    if (!cens_col %in% names(data)) {
      cli::cli_abort("Censoring column {.val {cens_col}} not found in data.")
    }
    if (!all(data[[cens_col]] %in% c(0L, 1L))) {
      cli::cli_abort("Censoring column {.val {cens_col}} must be binary (0/1).")
    }
  }

  # Auto-detect family
  if (is.null(family)) {
    family <- bc_suggest_family(data[[response]])
  }

  if (model_shape && family$family != "negbinomial") {
    cli::cli_warn("{.arg model_shape} is only supported for negative binomial. Ignoring.")
    model_shape <- FALSE
  }

  # Build formula
  rhs_terms <- method_col
  if (!is.null(covariates)) {
    rhs_terms <- c(rhs_terms, covariates)
  }
  if (!is.null(spline_by_method)) {
    rhs_terms <- c(rhs_terms,
                    sprintf("s(%s, by = %s, k = 3)", spline_by_method, method_col))
  }
  rhs_terms <- c(rhs_terms, sprintf("(1 | %s)", system_col))
  rhs <- paste(rhs_terms, collapse = " + ")

  # Build response term (with optional censoring)
  if (!is.null(cens_col)) {
    lhs <- sprintf("%s | cens(%s)", response, cens_col)
  } else {
    lhs <- response
  }

  if (model_shape && family$family == "negbinomial") {
    formula <- brms::bf(
      stats::as.formula(paste(lhs, "~", rhs)),
      stats::as.formula(paste("shape ~", method_col))
    )
  } else {
    formula <- brms::bf(stats::as.formula(paste(lhs, "~", rhs)))
  }

  # Default priors
  if (is.null(prior)) {
    prior <- bc_default_priors(family, has_shape_submodel = model_shape,
                                has_spline = !is.null(spline_by_method))
  }

  cli::cli_inform("Fitting {family$family} model with {chains} chains x {iter} iterations...")

  model <- brms::brm(
    formula = formula,
    data = data,
    family = family,
    prior = prior,
    chains = chains,
    iter = iter,
    warmup = warmup,
    cores = cores,
    seed = seed,
    backend = backend,
    control = list(adapt_delta = adapt_delta, max_treedepth = max_treedepth),
    file = file,
    ...
  )

  if (diagnostics) {
    bc_check_convergence(model)
    .report_shape(model, model_shape)
  }

  model
}

#' Fit a Bayesian benchmark model with a custom formula
#'
#' Full brms formula passthrough for factorial designs, interactions, and
#' custom random effects. Use when [bc_fit()] is too restrictive (e.g.,
#' `algorithm * rotation_removal` interactions or `(1 | mol_id:spin)`).
#'
#' @param data Long-format benchmark data.
#' @param formula A [brms::bf()] formula object.
#' @param family A brms family object. If `NULL`, auto-detected from the
#'   response variable in the formula.
#' @param prior A `brmsprior` object. If `NULL`, uses [bc_default_priors()].
#' @param cens_col Name of a binary censoring column (optional).
#' @param diagnostics Logical. Run convergence diagnostics after fitting?
#' @param chains,iter,warmup,cores,seed,backend,file,adapt_delta,max_treedepth
#'   Passed to [brms::brm()].
#' @param ... Additional arguments passed to [brms::brm()].
#' @return A `brmsfit` object.
#' @examples
#' \donttest{
#' data <- bc_simulate_benchmark(n_systems = 20)
#' formula <- brms::bf(count ~ method + (1 | system_id))
#' model <- bc_fit_design(data, formula = formula)
#' }
#' @family fitting
#' @export
bc_fit_design <- function(data,
                          formula,
                          family = NULL,
                          prior = NULL,
                          cens_col = NULL,
                          diagnostics = TRUE,
                          chains = 4,
                          iter = 4000,
                          warmup = 1000,
                          cores = 4,
                          seed = 1995,
                          backend = NULL,
                          file = NULL,
                          adapt_delta = 0.99,
                          max_treedepth = 12,
                          ...) {

  # Auto-detect backend
  if (is.null(backend)) {
    if (nzchar(system.file(package = "cmdstanr"))) {
      backend <- "cmdstanr"
    } else {
      backend <- "rstan"
      cli::cli_inform("cmdstanr not found, falling back to rstan backend.")
    }
  }

  if (!inherits(formula, "brmsformula")) {
    cli::cli_abort("{.arg formula} must be a brms formula (from {.fn brms::bf}).")
  }

  # Extract response variable name for family auto-detection
  resp_var <- all.vars(formula$formula)[1]

  if (is.null(family) && resp_var %in% names(data)) {
    family <- bc_suggest_family(data[[resp_var]])
  } else if (is.null(family)) {
    cli::cli_abort("Cannot auto-detect family: response {.val {resp_var}} not found in data.")
  }

  # Append censoring to formula if requested
  if (!is.null(cens_col)) {
    if (!cens_col %in% names(data)) {
      cli::cli_abort("Censoring column {.val {cens_col}} not found in data.")
    }
    # Modify the response term to include censoring
    orig_resp <- deparse(formula$formula[[2]])
    new_resp <- paste0(orig_resp, " | cens(", cens_col, ")")
    formula$formula[[2]] <- str2lang(new_resp)
  }

  if (is.null(prior)) {
    prior <- bc_default_priors(family)
  }

  cli::cli_inform("Fitting {family$family} model with {chains} chains x {iter} iterations...")

  model <- brms::brm(
    formula = formula,
    data = data,
    family = family,
    prior = prior,
    chains = chains,
    iter = iter,
    warmup = warmup,
    cores = cores,
    seed = seed,
    backend = backend,
    control = list(adapt_delta = adapt_delta, max_treedepth = max_treedepth),
    file = file,
    ...
  )

  if (diagnostics) {
    bc_check_convergence(model)
    .report_shape(model, model_shape = FALSE)
  }

  model
}

# Internal: report shape parameter for negbinomial models
.report_shape <- function(model, model_shape = FALSE) {
  if (!inherits(model, "brmsfit")) return(invisible(NULL))
  fam <- model$family$family
  if (!fam %in% c("negbinomial", "negbinomial2")) return(invisible(NULL))

  draws <- posterior::as_draws_df(model)

  if (model_shape) {
    # Shape submodel: report per-method
    shape_int <- draws[["b_shape_Intercept"]]
    shape_cols <- grep("^b_shape_", names(draws), value = TRUE)
    shape_cols <- setdiff(shape_cols, "b_shape_Intercept")

    ref_shape <- exp(stats::median(shape_int))
    cli::cli_inform("Shape (reference): {.val {round(ref_shape, 1)}} (median on response scale)")

    for (col in shape_cols) {
      method_name <- sub("^b_shape_method|^b_shape_Method", "", col)
      vals <- exp(shape_int + draws[[col]])
      med <- stats::median(vals)
      lo <- stats::quantile(vals, 0.025)
      hi <- stats::quantile(vals, 0.975)
      cli::cli_inform("Shape ({method_name}): {.val {round(med, 1)}} [{round(lo, 1)}, {round(hi, 1)}]")
    }
  } else {
    # Single shape
    if ("shape" %in% names(draws)) {
      vals <- draws[["shape"]]
      med <- stats::median(vals)
      lo <- stats::quantile(vals, 0.025)
      hi <- stats::quantile(vals, 0.975)

      disp_msg <- if (med > 100) {
        "low overdispersion (Poisson might suffice)"
      } else if (med < 50) {
        "high overdispersion"
      } else {
        "moderate overdispersion"
      }

      cli::cli_inform(c(
        "i" = "NB shape: {.val {round(med, 1)}} [{round(lo, 1)}, {round(hi, 1)}] -- {disp_msg}"
      ))
    }
  }
  invisible(NULL)
}

#' Fit a suite of models on the same benchmark data
#'
#' Fits separate models for count, time, and/or success responses on the
#' same benchmark data. Only fits models for responses that exist in the data.
#'
#' @param data Long-format benchmark data.
#' @param count_col Name of count column (default `"count"`). Set to `NULL`
#'   to skip.
#' @param time_col Name of time column (default `"time"`). Set to `NULL`
#'   to skip.
#' @param success_col Name of success column (default `"success"`). Set to
#'   `NULL` to skip.
#' @param file_prefix Prefix for cached model files (optional).
#' @param ... Additional arguments passed to [bc_fit()].
#' @return A named list of `brmsfit` objects.
#' @examples
#' \donttest{
#' data <- bc_simulate_benchmark(n_systems = 20)
#' models <- bc_fit_suite(data, count_col = "count",
#'   time_col = NULL, success_col = NULL)
#' }
#' @family fitting
#' @export
bc_fit_suite <- function(data,
                         count_col = "count",
                         time_col = "time",
                         success_col = "success",
                         file_prefix = NULL,
                         ...) {
  models <- list()

  responses <- list(
    count = list(col = count_col, family = brms::negbinomial(link = "log"),
                 shape = TRUE),
    time = list(col = time_col, family = brms::brmsfamily("Gamma", link = "log"),
                shape = FALSE),
    success = list(col = success_col, family = brms::bernoulli(link = "logit"),
                   shape = FALSE)
  )

  for (name in names(responses)) {
    spec <- responses[[name]]
    if (is.null(spec$col) || !spec$col %in% names(data)) next

    file_path <- if (!is.null(file_prefix)) {
      paste0(file_prefix, "_", name)
    } else {
      NULL
    }

    cli::cli_inform("Fitting {name} model...")
    models[[name]] <- bc_fit(
      data,
      response = spec$col,
      family = spec$family,
      model_shape = spec$shape,
      file = file_path,
      ...
    )
  }

  models
}

#' @srrstats {RE1.0} bc_fit constructs formulas. bc_fit_design accepts bf().
#' @srrstats {RE1.1} Formula construction documented in bc_fit.
#' @srrstats {RE1.2} Predictor types documented in bc_validate.
#' @srrstats {RE1.3} brmsfit retains input data and column names.
#' @srrstats {RE1.3a} bayescomp wraps brms (Bayesian regression); not
#'   OLS/WLS/GLS. Documented in vignettes and DESCRIPTION.
#' @srrstats {RE1.4} Model assumptions documented in vignettes.
#' @srrstats {RE3.0} bc_check_convergence warns on non-convergence.
#' @srrstats {RE3.1} bc_fit(diagnostics=FALSE) suppresses messages.
#' @srrstats {RE3.2} Default thresholds documented.
#' @srrstats {RE3.3} bc_check_convergence allows explicit thresholds.
#' @srrstats {RE4.0} Returns brmsfit objects.
#' @srrstats {RE4.1} brmsfit objects support print(), summary(), plot()
#'   for different output forms; bc_report() adds formatted text.
#' @srrstats {RE4.4} Returns brmsfit class with default print/plot methods.
#' @srrstats {RE4.5} brmsfit$residuals() returns residuals; not directly
#'   applicable to count/Bayesian models but accessible via brms API.
#' @srrstats {RE4.6} brms::predict() and brms::posterior_predict() return
#'   predicted values; bc_epred_draws wraps tidybayes.
#' @srrstats {RE4.8} brmsfit$formula contains model formula.
#' @srrstats {RE4.9} brmsfit contains all parameters for prediction via
#'   brms::predict() and brms::posterior_predict().
#' @srrstats {RE4.10} brmsfit components documented in brms package;
#'   bc_report() provides user-facing summary.
#' @srrstats {RE4.12} bc_epred_draws and brms::predict extract predictions;
#'   bc_summarize_effects extracts effect statistics.
#' @srrstats {RE4.13} brmsfit$fit (stanfit), $data, $formula, $prior all
#'   accessible; bc_summarize_effects extracts method effects.
#' @srrstats {RE4.14} brms::summary.brmsfit() implements summary method.
#' @srrstats {RE4.15} bc_summarize_effects provides CrI for effects;
#'   brms::predict provides CrI for predictions.
#' @srrstats {RE4.16} brmsfit residuals scaled by brms according to family
#'   (response vs link scale); not reimplemented here.
#' @srrstats {BS1.3} Computational params documented in bc_fit.
#' @srrstats {BS1.3a} brms supports previous fits via init.
#' @srrstats {BS1.3b} bc_fit backend selects cmdstanr or rstan.
#' @srrstats {BS1.4} diagnostics parameter controls convergence checking.
#' @srrstats {BS2.1} bc_validate ensures dimensional consistency.
#' @srrstats {BS2.1a} test-data_prep.R tests effects of bc_validate
#'   preprocessing on dimensional consistency.
#' @srrstats {BS2.6} Computational params validated by brms.
#' @srrstats {BS2.7} bc_fit passes seed to brms::brm.
#' @srrstats {BS2.8} brms file parameter caches fitted models; subsequent
#'   calls with same file= reuse previous results as starting point.
#' @srrstats {BS2.9} brms/Stan starts each chain with different seed by
#'   default (seed + chain_id offset).
#' @srrstats {BS2.10} brms/Stan handles seed-per-chain internally; passing
#'   identical seeds to chains is not possible via the brms API.
#' @srrstats {BS2.11} bc_fit does not accept starting values directly;
#'   brms init parameter handles this with appropriate naming.
#' @srrstats {BS2.12} diagnostics parameter controls verbosity.
#' @srrstats {BS2.13} bc_fit(diagnostics=FALSE) suppresses messages.
#' @srrstats {BS2.14} bc_fit(diagnostics=FALSE) suppresses convergence
#'   warnings; tested in test-models-validation.R.
#' @srrstats {BS2.15} cli::cli_abort throws catchable rlang conditions.
#' @srrstats {BS4.4} brms control(max_treedepth) limits computation;
#'   Stan's NUTS sampler terminates on convergence criteria.
#' @srrstats {BS4.6} test-recovery.R: convergence checker results
#'   (bc_check_convergence) consistent with fixed-sample estimates.
#' @noRd
NULL
