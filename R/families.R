#' Suggest appropriate brms family based on response variable
#'
#' Examines the response vector and suggests the most appropriate brms
#' family. Provides opinionated guidance: count data gets negative binomial
#' (not Gaussian), positive continuous gets Gamma, binary gets Bernoulli,
#' real-valued (with negatives) gets Student-t. Warns against Gaussian
#' for count or positive-only data, since Gaussian assumptions produce
#' misleading results in these cases (see Goswami 2025, arXiv:2505.13621).
#'
#' @param y Response vector.
#' @param type One of `"auto"`, `"count"`, `"time"`, `"success"`, `"real"`,
#'   or `"gaussian"`. When `"auto"`, the type is inferred from `y`.
#'   `"real"` selects Student-t for signed real-valued data (energy errors,
#'   barrier differences). `"gaussian"` forces Gaussian but warns if data
#'   looks like counts or positive-only.
#' @return A brms family object.
#' @examples
#' bc_suggest_family(c(100, 200, 50, 300))
#' bc_suggest_family(c(1.5, 2.3, 0.8), type = "time")
#' @family families
#' @export
bc_suggest_family <- function(y, type = c("auto", "count", "time", "success",
                                          "real", "gaussian")) {
  type <- match.arg(type)

  if (length(y) == 0 || all(is.na(y))) {
    cli::cli_abort("Response vector is empty or all NA. Cannot detect family.")
  }

  if (type == "auto") {
    if (is.logical(y) || all(y %in% c(0, 1), na.rm = TRUE)) {
      type <- "success"
    } else if (all(y == floor(y), na.rm = TRUE) && all(y >= 0, na.rm = TRUE)) {
      type <- "count"
    } else if (all(y > 0, na.rm = TRUE)) {
      type <- "time"
    } else {
      type <- "real"
    }
  }

  # Warn against Gaussian misuse
  if (type == "gaussian") {
    if (all(y == floor(y), na.rm = TRUE) && all(y >= 0, na.rm = TRUE)) {
      cli::cli_warn(c(
        "!" = "Data looks like non-negative integer counts.",
        "i" = "Gaussian models produce misleading results for count data.",
        "i" = "Consider {.code type = \"count\"} (negative binomial) instead."
      ))
    } else if (all(y > 0, na.rm = TRUE)) {
      cli::cli_warn(c(
        "!" = "Data is strictly positive.",
        "i" = "Gaussian assumes symmetric errors around zero.",
        "i" = "Consider {.code type = \"time\"} (Gamma) instead."
      ))
    }
  }

  switch(type,
    count = {
      mu <- mean(y, na.rm = TRUE)
      v <- stats::var(y, na.rm = TRUE)
      cli::cli_inform(c(
        "i" = "Count data detected. Using negative binomial (log link).",
        "i" = "Gaussian models produce misleading results for count data.",
        "i" = "Variance = {.val {round(v, 1)}}, mean = {.val {round(mu, 1)}}."
      ))
      brms::negbinomial(link = "log")
    },
    time = {
      cli::cli_inform(c(
        "i" = "Positive continuous data detected. Using Gamma (log link).",
        "i" = "Gaussian assumes symmetric errors around zero."
      ))
      brms::brmsfamily("Gamma", link = "log")
    },
    success = brms::bernoulli(link = "logit"),
    real = {
      cli::cli_inform(c(
        "i" = "Real-valued data with negatives detected. Using Student-t (identity link).",
        "i" = "Student-t is robust to outliers compared to Gaussian."
      ))
      brms::student(link = "identity")
    },
    gaussian = brms::brmsfamily("gaussian", link = "identity")
  )
}

#' Default weakly informative priors for benchmark models
#'
#' Returns a set of weakly informative priors appropriate for benchmark
#' comparison models. These are designed to regularize estimation in
#' small-sample settings (N=20-100 systems) without dominating the data.
#'
#' @param family A brms family object. Used to select appropriate priors.
#' @param has_shape_submodel Logical. If `TRUE`, adds priors for the shape
#'   submodel (relevant for negative binomial).
#' @param has_spline Logical. If `TRUE`, adds priors for smoothing spline
#'   hyperparameters (`sds` class). Only relevant when the formula includes
#'   `s()` terms.
#' @return A `brmsprior` object.
#' @examples
#' bc_default_priors()
#' bc_default_priors(family = brms::brmsfamily("Gamma", link = "log"))
#' @family families
#' @export
bc_default_priors <- function(family = brms::negbinomial(),
                              has_shape_submodel = FALSE,
                              has_spline = FALSE) {
  priors <- c(
    brms::prior(normal(0, 1), class = "b"),
    brms::prior(exponential(1), class = "sd"),
    brms::prior(student_t(3, 0, 2.5), class = "Intercept")
  )

  family_name <- family$family

  if (has_spline) {
    priors <- c(priors, brms::prior(exponential(2), class = "sds"))
  }

  if (family_name == "negbinomial") {
    if (has_shape_submodel) {
      priors <- c(priors, brms::prior(normal(0, 0.5), class = "b", dpar = "shape"))
    }
  } else if (family_name == "Gamma" || family_name == "gamma") {
    priors <- c(priors, brms::prior(gamma(0.01, 0.01), class = "shape"))
  } else if (family_name == "student") {
    priors <- c(priors, brms::prior(gamma(2, 0.1), class = "nu"))
  }

  priors
}
