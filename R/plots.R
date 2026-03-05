#' Conditional effects plot with raw data overlay
#'
#' Generates a publication-quality plot of conditional effects from a fitted
#' brms model, with the raw benchmark data overlaid as jittered points.
#'
#' When `show_extrapolation = TRUE` and original `data` is provided, the
#' plot marks the maximum observed covariate value per method with a
#' vertical dashed line and switches the prediction line from solid to
#' dashed beyond the observed range. This is important when ML-enhanced
#' methods converge with far fewer evaluations than classical baselines,
#' leaving no observed data in the high-effort regime (see Goswami 2025,
#' arXiv:2510.21368, Section 6.4.1).
#'
#' @param model A `brmsfit` object.
#' @param effects Character string specifying the conditional effects
#'   (e.g., `"RMSD_Init_Final:method"`).
#' @param data Original data for raw point overlay (optional).
#' @param response_col Response variable name in `data` for overlay.
#' @param covariate_col Name of the covariate column for extrapolation
#'   boundary detection (optional). Required when `show_extrapolation = TRUE`.
#' @param method_col Name of the method column in `data` (default `"method"`).
#' @param log_y Logical. Use log scale on y-axis? (default `TRUE`).
#' @param show_extrapolation Logical. If `TRUE`, marks the boundary
#'   between interpolation (observed range) and extrapolation (beyond
#'   observed range) per method. Requires `data` and `covariate_col`.
#' @param colors Named character vector of method colors. If `NULL`, uses
#'   the bayescomp palette.
#' @return A ggplot object.
#' @examples
#' \dontrun{
#' model <- bc_fit(bc_simulate_benchmark(), response = "count")
#' bc_plot_conditional(model, effects = "method")
#' }
#' @export
bc_plot_conditional <- function(model,
                                effects,
                                data = NULL,
                                response_col = "count",
                                covariate_col = NULL,
                                method_col = "method",
                                log_y = TRUE,
                                show_extrapolation = FALSE,
                                colors = NULL) {
  if (!inherits(model, "brmsfit")) {
    cli::cli_abort("{.arg model} must be a brmsfit object.")
  }

  cond <- brms::conditional_effects(model, effects = effects, points = TRUE)
  plot_data <- cond[[effects]]

  if (is.null(colors)) {
    methods <- levels(plot_data$method %||% plot_data$Method)
    if (is.null(methods)) methods <- unique(plot_data$method %||% plot_data$Method)
    n <- length(methods)
    colors <- stats::setNames(unname(bc_colors_discrete[seq_len(n)]), methods)
  }

  # Detect the method column name
  method_var <- if ("method" %in% names(plot_data)) "method" else "Method"

  p <- ggplot2::ggplot(plot_data,
    ggplot2::aes(
      x = .data[[names(plot_data)[1]]],
      y = .data$estimate__,
      color = .data[[method_var]],
      fill = .data[[method_var]]
    )
  ) +
    ggplot2::geom_ribbon(
      ggplot2::aes(ymin = .data$lower__, ymax = .data$upper__),
      alpha = 0.2, color = NA
    ) +
    ggplot2::geom_line(linewidth = 1.2)

  # Add raw data overlay
  if (!is.null(data) && response_col %in% names(data)) {
    p <- p + ggplot2::geom_jitter(
      data = data,
      ggplot2::aes(y = .data[[response_col]]),
      width = 0.03, height = 0, size = 2, alpha = 0.4, shape = 16
    )
  }

  # Extrapolation/interpolation distinction
  if (show_extrapolation && !is.null(data) && !is.null(covariate_col)) {
    if (!covariate_col %in% names(data)) {
      cli::cli_warn("Covariate {.val {covariate_col}} not found in data. Skipping extrapolation markers.")
    } else {
      # Find max observed covariate per method
      methods_in_data <- unique(data[[method_col]])
      max_obs <- vapply(methods_in_data, function(m) {
        max(data[[covariate_col]][data[[method_col]] == m], na.rm = TRUE)
      }, numeric(1))
      names(max_obs) <- methods_in_data

      # Add vertical dashed lines at max observed values
      for (i in seq_along(max_obs)) {
        m <- names(max_obs)[i]
        col <- if (!is.null(colors) && m %in% names(colors)) colors[[m]] else "grey40"
        p <- p + ggplot2::geom_vline(
          xintercept = max_obs[[i]], linetype = "dashed",
          color = col, linewidth = 0.5, alpha = 0.6
        )
      }

      # Split prediction lines into solid (interpolation) and dashed (extrapolation)
      x_var <- names(plot_data)[1]
      for (m in methods_in_data) {
        if (m %in% names(max_obs)) {
          extrap_data <- plot_data[plot_data[[method_var]] == m &
                                    plot_data[[x_var]] > max_obs[[m]], ]
          if (nrow(extrap_data) > 0) {
            p <- p + ggplot2::geom_line(
              data = extrap_data,
              ggplot2::aes(x = .data[[x_var]], y = .data$estimate__),
              linetype = "dashed", linewidth = 1.2, alpha = 0.6
            )
          }
        }
      }

      # Add annotation
      p <- p + ggplot2::annotate(
        "text", x = min(max_obs), y = Inf,
        label = "dashed = extrapolation", hjust = 0, vjust = 1.5,
        size = 3, fontface = "italic", color = "grey40"
      )
    }
  }

  p <- p +
    ggplot2::scale_color_manual(values = colors) +
    ggplot2::scale_fill_manual(values = colors) +
    ggplot2::labs(y = "Response") +
    theme_bayescomp()

  if (log_y) {
    p <- p + ggplot2::scale_y_log10()
  }

  p
}

#' Posterior predictive check plot
#'
#' @param model A `brmsfit` object.
#' @param ndraws Number of posterior draws (default 50).
#' @param type Type of pp_check (default `"dens_overlay"`).
#' @return A ggplot object.
#' @examples
#' \dontrun{
#' model <- bc_fit(bc_simulate_benchmark(), response = "count")
#' bc_plot_pp(model)
#' }
#' @export
bc_plot_pp <- function(model, ndraws = 50, type = "dens_overlay") {
  if (!inherits(model, "brmsfit")) {
    cli::cli_abort("{.arg model} must be a brmsfit object.")
  }
  bayesplot::pp_check(model, ndraws = ndraws, type = type) +
    theme_bayescomp()
}

#' Shape parameter posterior density comparison
#'
#' For negative binomial models with a shape submodel, plots the posterior
#' density of the shape parameter for each method level.
#'
#' @param model A `brmsfit` object with `shape ~ method`.
#' @param method_col Name of the method column (default `"method"`).
#' @param colors Named character vector of method colors.
#' @return A ggplot object.
#' @examples
#' \dontrun{
#' model <- bc_fit(bc_simulate_benchmark(), response = "count",
#'   model_shape = TRUE)
#' bc_plot_shape(model)
#' }
#' @export
bc_plot_shape <- function(model, method_col = "method", colors = NULL) {
  if (!inherits(model, "brmsfit")) {
    cli::cli_abort("{.arg model} must be a brmsfit object.")
  }

  draws <- posterior::as_draws_df(model)

  # Find shape columns
  shape_int <- grep("^b_shape_Intercept$", names(draws), value = TRUE)
  shape_method <- grep("^b_shape_", names(draws), value = TRUE)
  shape_method <- setdiff(shape_method, shape_int)

  if (length(shape_int) == 0) {
    cli::cli_abort("No shape submodel found in model.")
  }

  # Build shape draws per method
  method_levels <- levels(model$data[[method_col]])
  if (is.null(method_levels)) {
    method_levels <- unique(model$data[[method_col]])
  }

  shape_data <- data.frame(
    value = draws[[shape_int]],
    method = method_levels[1]
  )

  for (col in shape_method) {
    method_name <- sub("^b_shape_method|^b_shape_Method", "", col)
    shape_data <- rbind(shape_data, data.frame(
      value = draws[[shape_int]] + draws[[col]],
      method = method_name
    ))
  }

  if (is.null(colors)) {
    n <- length(unique(shape_data$method))
    colors <- stats::setNames(
      unname(bc_colors_discrete[seq_len(n)]),
      unique(shape_data$method)
    )
  }

  ggplot2::ggplot(shape_data,
    ggplot2::aes(x = .data$value, fill = .data$method, color = .data$method)
  ) +
    ggplot2::geom_density(alpha = 0.5, linewidth = 1.0) +
    ggplot2::scale_fill_manual(values = colors) +
    ggplot2::scale_color_manual(values = colors) +
    ggplot2::labs(
      x = "Shape Parameter (log scale)",
      y = "Posterior Density",
      fill = "Method", color = "Method"
    ) +
    theme_bayescomp() +
    ggplot2::theme(legend.position = "top")
}

#' LOO-PIT QQ plot
#'
#' Generates a LOO-PIT (Probability Integral Transform) QQ plot for
#' assessing model calibration.
#'
#' @param model A `brmsfit` object.
#' @param loo_result A `loo` object from [bc_loo()].
#' @param y Observed response vector.
#' @return A ggplot object.
#' @examples
#' \dontrun{
#' model <- bc_fit(bc_simulate_benchmark(), response = "count")
#' loo_result <- bc_loo(model)
#' bc_plot_loo_pit(model, loo_result, y = model$data$count)
#' }
#' @export
bc_plot_loo_pit <- function(model, loo_result, y) {
  if (!inherits(model, "brmsfit")) {
    cli::cli_abort("{.arg model} must be a brmsfit object.")
  }

  yrep <- brms::posterior_predict(model)
  bayesplot::ppc_loo_pit_qq(
    y = y,
    yrep = yrep,
    lw = loo::weights.importance_sampling(loo_result$psis_object)
  ) +
    theme_bayescomp()
}

#' Forest plot of method effects
#'
#' @param model A `brmsfit` object.
#' @param method_col Name of the method column (default `"method"`).
#' @param colors Named character vector of method colors.
#' @return A ggplot object.
#' @examples
#' \dontrun{
#' model <- bc_fit(bc_simulate_benchmark(), response = "count")
#' bc_plot_forest(model)
#' }
#' @export
bc_plot_forest <- function(model, method_col = "method", colors = NULL) {
  if (!inherits(model, "brmsfit")) {
    cli::cli_abort("{.arg model} must be a brmsfit object.")
  }

  effects <- bc_summarize_effects(model)
  method_effects <- effects[grepl("Percentage", effects$effect_type), ]

  if (is.null(colors)) {
    n <- nrow(method_effects)
    colors <- unname(bc_colors_discrete[seq_len(n)])
  }

  ggplot2::ggplot(method_effects,
    ggplot2::aes(
      x = .data$median,
      y = .data$effect_type,
      xmin = .data$lower,
      xmax = .data$upper
    )
  ) +
    ggplot2::geom_pointrange(color = colors[seq_len(nrow(method_effects))],
                              size = 0.8, linewidth = 0.8) +
    ggplot2::geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
    ggplot2::labs(x = "Percentage Change (%)", y = NULL) +
    theme_bayescomp()
}

#' Plot pairwise method contrasts
#'
#' Horizontal pointrange plot of all pairwise contrasts with a zero-line.
#'
#' @param contrasts A tibble from [bc_pairwise_contrasts()] with columns:
#'   contrast, estimate, lower, upper.
#' @param colors Character vector of colors for each contrast (optional).
#' @return A ggplot object.
#' @examples
#' \dontrun{
#' model <- bc_fit(bc_simulate_benchmark(), response = "count")
#' contrasts <- bc_pairwise_contrasts(model)
#' bc_plot_contrasts(contrasts)
#' }
#' @export
bc_plot_contrasts <- function(contrasts, colors = NULL) {
  if (!all(c("contrast", "estimate", "lower", "upper") %in% names(contrasts))) {
    cli::cli_abort("{.arg contrasts} must have columns: contrast, estimate, lower, upper.")
  }

  if (is.null(colors)) {
    n <- nrow(contrasts)
    colors <- unname(bc_colors_discrete[seq_len(n)])
  }

  ggplot2::ggplot(contrasts,
    ggplot2::aes(
      x = .data$estimate,
      y = .data$contrast,
      xmin = .data$lower,
      xmax = .data$upper
    )
  ) +
    ggplot2::geom_pointrange(color = colors[seq_len(nrow(contrasts))],
                              size = 0.8, linewidth = 0.8) +
    ggplot2::geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
    ggplot2::labs(x = "Contrast Estimate", y = NULL) +
    theme_bayescomp()
}

#' Pareto-k diagnostic plot
#'
#' Plots the Pareto-k values from LOO-CV, highlighting observations with
#' high influence (k > 0.7) or marginal influence (k > 0.5). Based on the
#' diagnostic framework in Vehtari, Gelman, and Gabry (2017).
#'
#' @param loo_result A `loo` object from [bc_loo()].
#' @param label_threshold Threshold above which to label points with their
#'   observation index (default 0.7).
#' @return A ggplot object.
#' @examples
#' \dontrun{
#' model <- bc_fit(bc_simulate_benchmark(), response = "count")
#' loo_result <- bc_loo(model)
#' bc_plot_pareto_k(loo_result)
#' }
#' @export
bc_plot_pareto_k <- function(loo_result, label_threshold = 0.7) {
  if (!inherits(loo_result, "loo")) {
    cli::cli_abort("{.arg loo_result} must be a loo object from {.fn bc_loo}.")
  }

  pk <- loo_result$diagnostics$pareto_k
  df <- data.frame(
    obs = seq_along(pk),
    pareto_k = pk,
    status = ifelse(pk > 0.7, "bad",
                    ifelse(pk > 0.5, "marginal", "good"))
  )
  df$status <- factor(df$status, levels = c("good", "marginal", "bad"))

  status_colors <- c(
    good = unname(bc_colors["teal"]),
    marginal = unname(bc_colors["sunshine"]),
    bad = unname(bc_colors["coral"])
  )

  p <- ggplot2::ggplot(df, ggplot2::aes(
    x = .data$obs, y = .data$pareto_k, color = .data$status
  )) +
    ggplot2::geom_point(size = 2, alpha = 0.7) +
    ggplot2::geom_hline(yintercept = 0.5, linetype = "dashed",
                         color = "grey60", linewidth = 0.5) +
    ggplot2::geom_hline(yintercept = 0.7, linetype = "dashed",
                         color = unname(bc_colors["coral"]), linewidth = 0.5) +
    ggplot2::scale_color_manual(values = status_colors, drop = FALSE) +
    ggplot2::labs(
      x = "Observation", y = "Pareto k",
      color = "Influence"
    ) +
    theme_bayescomp()

  # Label influential points
  bad_pts <- df[df$pareto_k > label_threshold, ]
  if (nrow(bad_pts) > 0) {
    p <- p + ggplot2::geom_text(
      data = bad_pts,
      ggplot2::aes(label = .data$obs),
      nudge_y = 0.03, size = 3, show.legend = FALSE
    )
  }

  p
}

#' Trace plots for MCMC diagnostics
#'
#' Generates trace plots for key model parameters showing chain mixing
#' and convergence. Wraps [bayesplot::mcmc_trace()] with the bayescomp
#' theme.
#'
#' @param model A `brmsfit` object.
#' @param pars Character vector of parameter names to plot. If `NULL`,
#'   plots the intercept, method effects, and random effect SD.
#' @return A ggplot object.
#' @examples
#' \dontrun{
#' model <- bc_fit(bc_simulate_benchmark(), response = "count")
#' bc_plot_trace(model)
#' }
#' @export
bc_plot_trace <- function(model, pars = NULL) {
  if (!inherits(model, "brmsfit")) {
    cli::cli_abort("{.arg model} must be a brmsfit object.")
  }

  draws <- posterior::as_draws_array(model)

  if (is.null(pars)) {
    all_vars <- posterior::variables(draws)
    pars <- grep("^b_|^sd_|^shape$|^nu$", all_vars, value = TRUE)
    if (length(pars) == 0) pars <- all_vars[seq_len(min(6, length(all_vars)))]
  }

  bayesplot::mcmc_trace(draws, pars = pars) +
    theme_bayescomp()
}

#' DHARMa residual diagnostics for brms models
#'
#' Produces simulated residual diagnostics using the DHARMa framework.
#' Checks for uniformity (QQ plot), overdispersion, and outliers.
#' Requires the `DHARMa` package.
#'
#' @param model A `brmsfit` object.
#' @param n_sim Number of simulations for residual calculation (default 250).
#' @return A DHARMa simulation object (invisibly). Produces diagnostic plots
#'   as a side effect.
#' @examples
#' \dontrun{
#' model <- bc_fit(bc_simulate_benchmark(), response = "count")
#' bc_dharma_check(model)
#' }
#' @export
bc_dharma_check <- function(model, n_sim = 250) {
  if (!inherits(model, "brmsfit")) {
    cli::cli_abort("{.arg model} must be a brmsfit object.")
  }
  if (!requireNamespace("DHARMa", quietly = TRUE)) {
    cli::cli_abort(
      "Package {.pkg DHARMa} is required for residual diagnostics. Install with {.code install.packages(\"DHARMa\")}."
    )
  }

  # Simulate from the posterior predictive
  yrep <- brms::posterior_predict(model, ndraws = n_sim)

  # Get observed response
  resp_var <- all.vars(model$formula$formula)[1]
  y <- model$data[[resp_var]]

  # Create DHARMa object
  sim <- DHARMa::createDHARMa(
    simulatedResponse = t(yrep),
    observedResponse = y,
    fittedPredictedResponse = apply(yrep, 2, stats::median),
    integerResponse = all(y == floor(y))
  )

  graphics::plot(sim)
  invisible(sim)
}

#' Cactus plot (cumulative performance profile)
#'
#' Shows what fraction of test systems each method solves within a given
#' budget of force evaluations (or time). This is the computational
#' equivalent of a performance profile from optimization benchmarking.
#'
#' @param data Long-format benchmark data with columns for system, method,
#'   and response.
#' @param response Name of the response column (default `"count"`).
#' @param method_col Name of the method column (default `"method"`).
#' @param max_budget Maximum budget to show on x-axis. If `NULL`, uses
#'   the maximum observed value.
#' @param colors Named character vector of method colors.
#' @param log_x Logical. Use log scale on x-axis? (default `FALSE`).
#' @return A ggplot object.
#' @examples
#' data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2)
#' bc_plot_cactus(data)
#' @export
bc_plot_cactus <- function(data,
                           response = "count",
                           method_col = "method",
                           max_budget = NULL,
                           colors = NULL,
                           log_x = FALSE) {
  if (!response %in% names(data)) {
    cli::cli_abort("Response column {.val {response}} not found in data.")
  }
  if (!method_col %in% names(data)) {
    cli::cli_abort("Method column {.val {method_col}} not found in data.")
  }

  methods <- levels(data[[method_col]])
  if (is.null(methods)) methods <- unique(data[[method_col]])
  if (is.null(max_budget)) max_budget <- max(data[[response]], na.rm = TRUE)

  # Build cumulative profile per method
  profiles <- lapply(methods, function(m) {
    vals <- sort(data[[response]][data[[method_col]] == m])
    n <- length(vals)
    data.frame(
      method = m,
      budget = vals,
      fraction = seq_len(n) / n,
      stringsAsFactors = FALSE
    )
  })
  prof_df <- do.call(rbind, profiles)
  prof_df$method <- factor(prof_df$method, levels = methods)

  if (is.null(colors)) {
    n <- length(methods)
    colors <- stats::setNames(unname(bc_colors_discrete[seq_len(n)]), methods)
  }

  p <- ggplot2::ggplot(prof_df, ggplot2::aes(
    x = .data$budget, y = .data$fraction, color = .data$method
  )) +
    ggplot2::geom_step(linewidth = 1.2) +
    ggplot2::scale_color_manual(values = colors) +
    ggplot2::coord_cartesian(xlim = c(0, max_budget)) +
    ggplot2::labs(
      x = "Budget (force evaluations)",
      y = "Fraction of systems solved",
      color = "Method"
    ) +
    theme_bayescomp()

  if (log_x) p <- p + ggplot2::scale_x_log10()
  p
}

#' Performance profile (ratio-based)
#'
#' Shows what fraction of test systems each method solves within a given
#' ratio of the best method's cost. A standard visualization from
#' optimization benchmarking (Dolan and More, 2002).
#'
#' @param data Long-format benchmark data.
#' @param response Name of the response column (default `"count"`).
#' @param method_col Name of the method column (default `"method"`).
#' @param system_col Name of the system column (default `"system_id"`).
#' @param max_ratio Maximum performance ratio to show (default 10).
#' @param colors Named character vector of method colors.
#' @return A ggplot object.
#' @examples
#' data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2)
#' bc_plot_performance_profile(data)
#' @export
bc_plot_performance_profile <- function(data,
                                        response = "count",
                                        method_col = "method",
                                        system_col = "system_id",
                                        max_ratio = 10,
                                        colors = NULL) {
  if (!all(c(response, method_col, system_col) %in% names(data))) {
    cli::cli_abort("Required columns not found in data.")
  }

  methods <- levels(data[[method_col]])
  if (is.null(methods)) methods <- unique(data[[method_col]])

  # Compute best cost per system
  best <- stats::aggregate(
    data[[response]],
    by = list(system = data[[system_col]]),
    FUN = min, na.rm = TRUE
  )
  names(best) <- c("system", "best_cost")

  # Compute ratios
  data_with_ratio <- merge(data, best,
                            by.x = system_col, by.y = "system")
  data_with_ratio$ratio <- data_with_ratio[[response]] / data_with_ratio$best_cost

  # Build profile per method
  profiles <- lapply(methods, function(m) {
    ratios <- sort(data_with_ratio$ratio[data_with_ratio[[method_col]] == m])
    n <- length(ratios)
    data.frame(
      method = m,
      ratio = ratios,
      fraction = seq_len(n) / n,
      stringsAsFactors = FALSE
    )
  })
  prof_df <- do.call(rbind, profiles)
  prof_df$method <- factor(prof_df$method, levels = methods)

  if (is.null(colors)) {
    n <- length(methods)
    colors <- stats::setNames(unname(bc_colors_discrete[seq_len(n)]), methods)
  }

  ggplot2::ggplot(prof_df, ggplot2::aes(
    x = .data$ratio, y = .data$fraction, color = .data$method
  )) +
    ggplot2::geom_step(linewidth = 1.2) +
    ggplot2::scale_color_manual(values = colors) +
    ggplot2::coord_cartesian(xlim = c(1, max_ratio)) +
    ggplot2::labs(
      x = "Performance ratio (cost / best cost)",
      y = "Fraction of systems",
      color = "Method"
    ) +
    theme_bayescomp()
}

#' Dumbbell plot for paired method comparison
#'
#' Shows paired values for two methods connected by segments, with the
#' difference labeled. Systems are sorted by the reference method's cost.
#' This is the primary comparison visualization in the OCI-NEB paper.
#'
#' @param data Long-format benchmark data.
#' @param response Name of the response column (default `"count"`).
#' @param method_col Name of the method column (default `"method"`).
#' @param system_col Name of the system column (default `"system_id"`).
#' @param colors Named character vector of two method colors. If `NULL`,
#'   uses coral (reference) and teal (treatment).
#' @param show_labels Logical. Show speedup ratio labels? (default `TRUE`).
#' @param cap_value Maximum value to display (for capping failed runs).
#'   `NULL` for no capping.
#' @return A ggplot object.
#' @examples
#' data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2)
#' bc_plot_dumbbell(data)
#' @export
bc_plot_dumbbell <- function(data,
                             response = "count",
                             method_col = "method",
                             system_col = "system_id",
                             colors = NULL,
                             show_labels = TRUE,
                             cap_value = NULL) {
  if (!all(c(response, method_col, system_col) %in% names(data))) {
    cli::cli_abort("Required columns not found in data.")
  }

  methods <- levels(data[[method_col]])
  if (is.null(methods)) methods <- unique(data[[method_col]])
  if (length(methods) != 2) {
    cli::cli_abort("Dumbbell plot requires exactly 2 methods, got {length(methods)}.")
  }

  if (is.null(colors)) {
    colors <- stats::setNames(
      c(unname(bc_colors["coral"]), unname(bc_colors["teal"])),
      methods
    )
  }

  # Pivot to wide for paired comparison
  wide <- tidyr::pivot_wider(
    data[, c(system_col, method_col, response)],
    names_from = dplyr::all_of(method_col),
    values_from = dplyr::all_of(response)
  )

  if (!is.null(cap_value)) {
    wide[[methods[1]]] <- pmin(wide[[methods[1]]], cap_value)
    wide[[methods[2]]] <- pmin(wide[[methods[2]]], cap_value)
  }

  wide$ratio <- wide[[methods[1]]] / pmax(wide[[methods[2]]], .Machine$double.eps)

  # Sort by reference method cost
  wide <- wide[order(wide[[methods[1]]]), ]
  wide[[system_col]] <- factor(wide[[system_col]],
                                levels = wide[[system_col]])

  y_pos <- seq_len(nrow(wide))

  p <- ggplot2::ggplot(wide) +
    ggplot2::geom_segment(
      ggplot2::aes(
        x = .data[[methods[2]]], xend = .data[[methods[1]]],
        y = .data[[system_col]], yend = .data[[system_col]]
      ),
      color = unname(bc_colors["teal"]), linewidth = 0.8, alpha = 0.5
    ) +
    ggplot2::geom_point(
      ggplot2::aes(x = .data[[methods[1]]], y = .data[[system_col]]),
      color = colors[methods[1]], size = 2.5
    ) +
    ggplot2::geom_point(
      ggplot2::aes(x = .data[[methods[2]]], y = .data[[system_col]]),
      color = colors[methods[2]], size = 2.5
    ) +
    ggplot2::scale_y_discrete(limits = rev) +
    ggplot2::labs(
      x = "Force evaluations",
      y = NULL
    ) +
    theme_bayescomp()

  if (show_labels) {
    wide$label <- sprintf("%.1fx", wide$ratio)
    wide$label_x <- pmax(wide[[methods[1]]], wide[[methods[2]]]) * 1.05
    p <- p + ggplot2::geom_text(
      data = wide,
      ggplot2::aes(x = .data$label_x, y = .data[[system_col]],
                    label = .data$label),
      size = 2.5, hjust = 0, color = unname(bc_colors["teal"])
    )
  }

  p
}

#' Violin plot for method comparison
#'
#' Shows the distribution of a response variable by method using violin
#' plots with overlaid boxplots and jittered raw points.
#'
#' @param data Long-format benchmark data.
#' @param response Name of the response column (default `"count"`).
#' @param method_col Name of the method column (default `"method"`).
#' @param colors Named character vector of method colors.
#' @param log_y Logical. Use log scale on y-axis? (default `FALSE`).
#' @return A ggplot object.
#' @examples
#' data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2)
#' bc_plot_violin(data)
#' @export
bc_plot_violin <- function(data,
                           response = "count",
                           method_col = "method",
                           colors = NULL,
                           log_y = FALSE) {
  if (!all(c(response, method_col) %in% names(data))) {
    cli::cli_abort("Required columns not found in data.")
  }

  methods <- levels(data[[method_col]])
  if (is.null(methods)) methods <- unique(data[[method_col]])

  if (is.null(colors)) {
    n <- length(methods)
    colors <- stats::setNames(unname(bc_colors_discrete[seq_len(n)]), methods)
  }

  p <- ggplot2::ggplot(data, ggplot2::aes(
    x = .data[[method_col]], y = .data[[response]],
    fill = .data[[method_col]]
  )) +
    ggplot2::geom_violin(alpha = 0.4, color = unname(bc_colors["teal"])) +
    ggplot2::geom_boxplot(width = 0.15, fill = "white",
                           color = unname(bc_colors["teal"]),
                           outlier.shape = NA) +
    ggplot2::geom_jitter(width = 0.08, size = 1.5, alpha = 0.6,
                          color = unname(bc_colors["teal"])) +
    ggplot2::scale_fill_manual(values = colors) +
    ggplot2::labs(x = NULL, y = response, fill = "Method") +
    theme_bayescomp() +
    ggplot2::theme(legend.position = "none")

  if (log_y) p <- p + ggplot2::scale_y_log10()
  p
}

#' Signed method difference plot
#'
#' Shows the signed difference between two methods for each system,
#' sorted by an auxiliary variable (e.g., RMSD). Points are colored
#' by which method is better. Includes median and percentile reference
#' lines.
#'
#' @param data Long-format benchmark data.
#' @param response Name of the response column (default `"count"`).
#' @param method_col Name of the method column (default `"method"`).
#' @param system_col Name of the system column (default `"system_id"`).
#' @param sort_by Column to sort systems by (optional). If `NULL`, sorts
#'   by the difference itself.
#' @param as_ratio Logical. Show ratio instead of raw difference?
#'   (default `TRUE`).
#' @param colors Two-element character vector for
#'   (method1 better, method2 better). Default: teal, coral.
#' @return A ggplot object.
#' @examples
#' data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2)
#' bc_plot_method_diff(data)
#' @export
bc_plot_method_diff <- function(data,
                                response = "count",
                                method_col = "method",
                                system_col = "system_id",
                                sort_by = NULL,
                                as_ratio = TRUE,
                                colors = NULL) {
  if (!all(c(response, method_col, system_col) %in% names(data))) {
    cli::cli_abort("Required columns not found in data.")
  }

  methods <- levels(data[[method_col]])
  if (is.null(methods)) methods <- unique(data[[method_col]])
  if (length(methods) != 2) {
    cli::cli_abort("Method difference plot requires exactly 2 methods.")
  }

  if (is.null(colors)) {
    colors <- c(unname(bc_colors["teal"]), unname(bc_colors["coral"]))
  }

  # Pivot to wide
  cols_keep <- unique(c(system_col, method_col, response, sort_by))
  cols_keep <- cols_keep[cols_keep %in% names(data)]
  wide <- tidyr::pivot_wider(
    data[, cols_keep],
    names_from = dplyr::all_of(method_col),
    values_from = dplyr::all_of(response)
  )

  if (as_ratio) {
    wide$diff <- wide[[methods[1]]] / pmax(wide[[methods[2]]], .Machine$double.eps)
    ylab <- sprintf("Ratio (%s / %s)", methods[1], methods[2])
    ref_line <- 1
  } else {
    wide$diff <- wide[[methods[1]]] - wide[[methods[2]]]
    ylab <- sprintf("Difference (%s - %s)", methods[1], methods[2])
    ref_line <- 0
  }

  wide$better <- ifelse(wide$diff > ref_line, methods[1], methods[2])

  # Sort
  if (!is.null(sort_by) && sort_by %in% names(wide)) {
    wide <- wide[order(wide[[sort_by]]), ]
  } else {
    wide <- wide[order(wide$diff), ]
  }
  wide$rank <- seq_len(nrow(wide))

  med_diff <- stats::median(wide$diff, na.rm = TRUE)

  ggplot2::ggplot(wide, ggplot2::aes(
    x = .data$rank, y = .data$diff, color = .data$better
  )) +
    ggplot2::geom_point(size = 2.5, alpha = 0.7) +
    ggplot2::geom_hline(yintercept = ref_line, linetype = "dashed",
                         color = "grey50") +
    ggplot2::geom_hline(yintercept = med_diff, linetype = "solid",
                         color = unname(bc_colors["teal"]), linewidth = 0.8) +
    ggplot2::scale_color_manual(
      values = stats::setNames(colors, methods),
      name = "Faster method"
    ) +
    ggplot2::annotate("text", x = nrow(wide) * 0.95, y = med_diff,
                       label = sprintf("median = %.2f", med_diff),
                       vjust = -0.5, hjust = 1, size = 3.5,
                       color = unname(bc_colors["teal"])) +
    ggplot2::labs(x = "System (sorted)", y = ylab) +
    theme_bayescomp()
}

#' Scatter comparison of two methods (1:1 plot)
#'
#' Scatter plot of method A cost vs method B cost with a 1:1 identity
#' line. Points are colored by which method is cheaper.
#'
#' @param data Long-format benchmark data.
#' @param response Name of the response column (default `"count"`).
#' @param method_col Name of the method column (default `"method"`).
#' @param system_col Name of the system column (default `"system_id"`).
#' @param log_scale Logical. Use log scale on both axes? (default `TRUE`).
#' @param colors Two-element character vector for (method1 better,
#'   method2 better).
#' @return A ggplot object.
#' @examples
#' data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2)
#' bc_plot_scatter_comparison(data)
#' @export
bc_plot_scatter_comparison <- function(data,
                                       response = "count",
                                       method_col = "method",
                                       system_col = "system_id",
                                       log_scale = TRUE,
                                       colors = NULL) {
  if (!all(c(response, method_col, system_col) %in% names(data))) {
    cli::cli_abort("Required columns not found in data.")
  }

  methods <- levels(data[[method_col]])
  if (is.null(methods)) methods <- unique(data[[method_col]])
  if (length(methods) != 2) {
    cli::cli_abort("Scatter comparison requires exactly 2 methods.")
  }

  if (is.null(colors)) {
    colors <- c(unname(bc_colors["teal"]), unname(bc_colors["coral"]))
  }

  wide <- tidyr::pivot_wider(
    data[, c(system_col, method_col, response)],
    names_from = dplyr::all_of(method_col),
    values_from = dplyr::all_of(response)
  )

  wide$better <- ifelse(wide[[methods[2]]] < wide[[methods[1]]],
                         methods[2], methods[1])

  lims <- range(c(wide[[methods[1]]], wide[[methods[2]]]), na.rm = TRUE)

  p <- ggplot2::ggplot(wide, ggplot2::aes(
    x = .data[[methods[1]]], y = .data[[methods[2]]],
    color = .data$better
  )) +
    ggplot2::geom_abline(slope = 1, intercept = 0, linetype = "dashed",
                          color = "grey50") +
    ggplot2::geom_point(size = 3, alpha = 0.7) +
    ggplot2::scale_color_manual(
      values = stats::setNames(colors, methods),
      name = "Faster"
    ) +
    ggplot2::labs(x = methods[1], y = methods[2]) +
    ggplot2::coord_fixed() +
    theme_bayescomp()

  if (log_scale) {
    p <- p +
      ggplot2::scale_x_log10() +
      ggplot2::scale_y_log10()
  }

  p
}
