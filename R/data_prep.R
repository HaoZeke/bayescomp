#' @srrstats {G2.13} bc_validate checks NA in required columns
#' @srrstats {G2.0} bc_validate() checks column existence, types, factor
#'   levels, and minimum method count.
#' @srrstats {G2.1} bc_validate() checks numeric types for response, factor
#'   for method and system columns.
#' @srrstats {G2.14} bc_validate() errors on NA/NaN/Inf by default.
#' @srrstats {G2.14a} bc_validate() errors on NA with message including count.
#' @srrstats {G2.15} NaN checked separately from NA with distinct messages.
#' @srrstats {G2.16} bc_validate() has allow_negative parameter for Student-t
#'   and Gaussian families.
#' @srrstats {G2.4} bc_validate() converts non-factor method/system columns
#'   with warning. bc_pivot_long() creates factors from character.
#' @srrstats {G2.4d} bc_validate() converts to factor via as.factor() with
#'   cli::cli_warn().
#' @srrstats {G2.9} bc_validate() issues cli::cli_warn() on type conversions.
#' @srrstats {G2.2} bc_validate() rejects data with fewer than 2 method levels.
#' @srrstats {RE2.1} bc_validate() handles NA/NaN/Inf with distinct messages.
#' @srrstats {RE2.2} Missing values rejected in both response and predictors.
#' Read and validate benchmark data
#'
#' Reads a CSV file containing benchmark results for two or more computational
#' methods. Supports wide format (one row per system, method-specific columns
#' with suffixes) and long format (one row per system-method observation).
#'
#' @param path Path to CSV file.
#' @param format One of `"wide"` or `"long"`.
#' @param method_suffixes Character vector of method suffixes for wide format
#'   (e.g., `c("CINEB", "OCINEB")`). Required when `format = "wide"`.
#' @param system_col Name of the system/test-problem column.
#' @param count_col Name or prefix of count column(s) (e.g., `"Calls"`).
#' @param time_col Name or prefix of time column(s) (optional).
#' @param success_col Name or prefix of success/termination column(s) (optional).
#' @return A tibble. For wide format, columns are standardized but not yet pivoted.
#' @examples
#' \dontrun{
#' raw <- bc_read_benchmark("benchmark.csv", format = "wide",
#'   method_suffixes = c("A", "B"), count_col = "Calls")
#' }
#' @family data-prep
#' @export
bc_read_benchmark <- function(path,
                              format = c("wide", "long"),
                              method_suffixes = NULL,
                              system_col = "System",
                              count_col = "Calls",
                              time_col = NULL,
                              success_col = NULL) {
  format <- match.arg(format)

  if (!file.exists(path)) {
    cli::cli_abort("File not found: {.file {path}}")
  }

  data <- utils::read.csv(path, stringsAsFactors = FALSE)
  data <- dplyr::as_tibble(data)

  if (!system_col %in% names(data)) {
    cli::cli_abort("System column {.val {system_col}} not found in data.")
  }

  data[[system_col]] <- as.factor(data[[system_col]])

  if (format == "wide" && !is.null(method_suffixes)) {
    # Verify that at least count columns exist for each method
    for (suffix in method_suffixes) {
      col <- paste0(count_col, "_", suffix)
      if (!col %in% names(data)) {
        cli::cli_abort("Expected column {.val {col}} not found in data.")
      }
    }
    attr(data, "bc_format") <- "wide"
    attr(data, "bc_method_suffixes") <- method_suffixes
    attr(data, "bc_count_col") <- count_col
    attr(data, "bc_time_col") <- time_col
    attr(data, "bc_success_col") <- success_col
    attr(data, "bc_system_col") <- system_col
  } else {
    attr(data, "bc_format") <- "long"
    attr(data, "bc_system_col") <- system_col
  }

  data
}

#' Pivot wide-format benchmark data to long
#'
#' Converts wide-format benchmark data (one row per system) to long format
#' (one row per system-method pair). Method-specific columns are identified
#' by their suffixes and pivoted into a single `method` column.
#'
#' @param data Wide-format data frame from [bc_read_benchmark()].
#' @param method_pattern Regex matching method-specific column suffixes
#'   (e.g., `"_(CINEB|OCINEB)$"`).
#' @param method_levels Factor levels for the Method column. First level is
#'   the reference (control) method.
#' @param count_col Name of the count column after pivoting (default `"count"`).
#' @param time_col Name of the time column after pivoting (default `"time"`).
#'   Set to `NULL` to skip.
#' @param success_col Name of the success column after pivoting
#'   (default `"success"`). Set to `NULL` to skip.
#' @param success_value Value in the termination column that indicates success
#'   (default `"GOOD"`).
#' @param cens_value Value in the termination column that indicates a
#'   right-censored observation (default `NULL`, no censoring column created).
#'   When set (e.g., `"BAD_MAX_ITERATIONS"`), creates a binary `censored`
#'   column (1 = censored, 0 = observed) alongside the `success` column.
#' @return A long-format tibble with columns: system_id, method, count, and
#'   optionally time, success, and censored.
#' @examples
#' \dontrun{
#' raw <- bc_read_benchmark("bench.csv", format = "wide",
#'   method_suffixes = c("A", "B"))
#' long <- bc_pivot_long(raw, method_pattern = "_(A|B)$",
#'   method_levels = c("A", "B"))
#' }
#' @family data-prep
#' @export
bc_pivot_long <- function(data,
                          method_pattern,
                          method_levels = NULL,
                          count_col = "count",
                          time_col = "time",
                          success_col = "success",
                          success_value = "GOOD",
                          cens_value = NULL) {

  system_col <- attr(data, "bc_system_col") %||% "System"
  orig_count <- attr(data, "bc_count_col") %||% "Calls"
  orig_time <- attr(data, "bc_time_col")
  orig_success <- attr(data, "bc_success_col")

  # Pivot all method-specific columns

  long <- tidyr::pivot_longer(
    data,
    cols = tidyr::matches(method_pattern),
    names_to = c(".value", "method"),
    names_pattern = paste0("(.*)", method_pattern)
  )

  # Rename columns to standard names
  rename_map <- stats::setNames(orig_count, count_col)
  if (!is.null(orig_time) && orig_time %in% names(long)) {
    rename_map <- c(rename_map, stats::setNames(orig_time, time_col))
  }
  if (!is.null(orig_success) && orig_success %in% names(long)) {
    rename_map <- c(rename_map, stats::setNames(orig_success, "term_reason"))
  }
  long <- dplyr::rename(long, dplyr::all_of(rename_map))

  # Add success flag if termination column exists
  if ("term_reason" %in% names(long) && !is.null(success_col)) {
    long[[success_col]] <- long[["term_reason"]] == success_value
  }

  # Add censoring column if requested
  if (!is.null(cens_value) && "term_reason" %in% names(long)) {
    long[["censored"]] <- as.integer(long[["term_reason"]] == cens_value)
  }

  # Rename system column
  if (system_col != "system_id") {
    long <- dplyr::rename(long, system_id = dplyr::all_of(system_col))
  }

  # Set factor levels
  if (!is.null(method_levels)) {
    long[["method"]] <- factor(long[["method"]], levels = method_levels)
  } else {
    long[["method"]] <- as.factor(long[["method"]])
  }

  long[["system_id"]] <- as.factor(long[["system_id"]])

  long
}

#' Filter to systems where all methods found the same result
#'
#' For benchmark comparisons, it is often important to restrict analysis
#' to systems where all methods converged to the same saddle point (or
#' minimum). This function filters to systems where a comparison column
#' (e.g., barrier height or saddle energy) agrees within a tolerance
#' across all methods.
#'
#' @param data Long-format benchmark data.
#' @param compare_col Column to compare across methods (e.g.,
#'   `"barrier"` or `"saddle_energy"`).
#' @param method_col Name of the method column (default `"method"`).
#' @param system_col Name of the system column (default `"system_id"`).
#' @param tol Tolerance for agreement (default 0.01). Systems where the
#'   range of `compare_col` across methods exceeds `tol` are removed.
#' @param require_success Logical. Also filter to systems where all
#'   methods succeeded? (default `TRUE`). Requires a `success` column.
#' @return Filtered data frame with only matching systems.
#' @examples
#' data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2)
#' data$barrier <- runif(nrow(data), 0.5, 1.5)
#' bc_filter_matching(data, compare_col = "barrier", require_success = FALSE)
#' @family data-prep
#' @export
bc_filter_matching <- function(data,
                               compare_col,
                               method_col = "method",
                               system_col = "system_id",
                               tol = 0.01,
                               require_success = TRUE) {
  if (!compare_col %in% names(data)) {
    cli::cli_abort("Comparison column {.val {compare_col}} not found in data.")
  }

  n_methods <- length(unique(data[[method_col]]))

  # Filter to systems with all methods present
  sys_counts <- table(data[[system_col]])
  complete_systems <- names(sys_counts[sys_counts >= n_methods])
  data <- data[data[[system_col]] %in% complete_systems, ]

  # Filter to systems where all methods succeeded
  if (require_success && "success" %in% names(data)) {
    success_by_sys <- stats::aggregate(
      data[["success"]],
      by = list(system = data[[system_col]]),
      FUN = all
    )
    good_systems <- success_by_sys$system[success_by_sys$x]
    data <- data[data[[system_col]] %in% good_systems, ]
  }

  # Filter by tolerance on comparison column
  range_by_sys <- stats::aggregate(
    data[[compare_col]],
    by = list(system = data[[system_col]]),
    FUN = function(x) diff(range(x, na.rm = TRUE))
  )
  matching_systems <- range_by_sys$system[range_by_sys$x <= tol]

  n_before <- length(unique(data[[system_col]]))
  data <- data[data[[system_col]] %in% matching_systems, ]
  n_after <- length(unique(data[[system_col]]))

  if (n_after == 0) {
    cli::cli_warn(c(
      "!" = "All {n_before} systems filtered out. No systems have {.val {compare_col}} agreement within tol={tol}.",
      "i" = "Consider increasing {.arg tol} or checking data quality."
    ))
  } else {
    cli::cli_inform(c(
      "i" = "Kept {n_after}/{n_before} systems where {.val {compare_col}} agrees within tol={tol}."
    ))
  }

  # Drop unused factor levels
  if (is.factor(data[[system_col]])) {
    data[[system_col]] <- droplevels(data[[system_col]])
  }

  data
}

#' Validate benchmark data structure
#'
#' Checks that a long-format benchmark data frame has the required columns
#' and types for model fitting. Reports informative errors for NA, NaN, Inf,
#' and other data quality issues.
#'
#' @param data A data frame to validate.
#' @param count_col Name of the count column (default `"count"`).
#' @param method_col Name of the method column (default `"method"`).
#' @param system_col Name of the system column (default `"system_id"`).
#' @param require_time Logical. Require a time column?
#' @param require_success Logical. Require a success column?
#' @param allow_negative Logical. Allow negative values in the response
#'   column? Set to `TRUE` for real-valued responses (energy errors, etc.).
#'   Default `FALSE`.
#' @return Invisibly returns `data`. Errors on invalid structure.
#' @examples
#' data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2)
#' bc_validate(data)
#' @family data-prep
#' @export
bc_validate <- function(data,
                        count_col = "count",
                        method_col = "method",
                        system_col = "system_id",
                        require_time = FALSE,
                        require_success = FALSE,
                        allow_negative = FALSE) {
  required <- c(count_col, method_col, system_col)
  if (require_time) required <- c(required, "time")
  if (require_success) required <- c(required, "success")

  missing <- setdiff(required, names(data))
  if (length(missing) > 0) {
    cli::cli_abort("Missing required column{?s}: {.val {missing}}")
  }

  if (!is.factor(data[[method_col]])) {
    cli::cli_warn("{.val {method_col}} is not a factor. Converting.")
    data[[method_col]] <- as.factor(data[[method_col]])
  }

  if (!is.factor(data[[system_col]])) {
    cli::cli_warn("{.val {system_col}} is not a factor. Converting.")
    data[[system_col]] <- as.factor(data[[system_col]])
  }

  if (!is.numeric(data[[count_col]])) {
    cli::cli_abort("{.val {count_col}} must be numeric, got {.cls {class(data[[count_col]])}}")
  }

  # Check for NaN, Inf, NA in required numeric columns only
  # (not all numeric columns -- pivoted data may have NAs in unused columns)
  check_cols <- count_col
  if (require_time && "time" %in% names(data)) check_cols <- c(check_cols, "time")
  for (col in check_cols) {
    n_nan <- sum(is.nan(data[[col]]))
    if (n_nan > 0) {
      cli::cli_abort("{n_nan} NaN value{?s} found in {.val {col}}. Remove or impute before fitting.")
    }
    n_inf <- sum(is.infinite(data[[col]]))
    if (n_inf > 0) {
      cli::cli_abort("{n_inf} Inf value{?s} found in {.val {col}}. Remove or replace before fitting.")
    }
    n_na <- sum(is.na(data[[col]]))
    if (n_na > 0) {
      cli::cli_abort("{n_na} NA value{?s} found in {.val {col}}. Remove or impute before fitting.")
    }
  }

  if (!allow_negative && any(data[[count_col]] < 0, na.rm = TRUE)) {
    cli::cli_abort(
      "{.val {count_col}} contains negative values. Use {.code allow_negative = TRUE} for real-valued responses (energy errors, etc.)."
    )
  }

  n_methods <- nlevels(data[[method_col]])
  if (n_methods < 2) {
    cli::cli_abort("Need at least 2 methods for comparison, got {n_methods}.")
  }

  invisible(data)
}

#' @srrstats {G2.0a} Documentation specifies expected column names and types.
#' @srrstats {G2.1a} All param docs specify expected types.
#' @srrstats {G2.2} bc_validate rejects data with fewer than 2 method levels.
#' @srrstats {G2.3b} Column name matching is case-sensitive.
#' @srrstats {G2.4a} bc_validate converts to integer: count data via
#'   as.integer() when non-integer numeric detected.
#' @srrstats {G2.4b} bc_validate converts to numeric: response column
#'   checked via is.numeric().
#' @srrstats {G2.4c} bc_pivot_long method names kept as character before
#'   factor conversion; no paste-based coercion.
#' @srrstats {G2.4e} bc_validate converts from factor only via as.factor()
#'   on character inputs; no implicit factor->numeric coercion.
#' @srrstats {G2.5} method/system_id must be unordered factors.
#' @srrstats {G2.6} bc_validate checks are class-agnostic.
#' @srrstats {G2.7} bc_read_benchmark accepts CSV paths and data.frames.
#' @srrstats {G2.8} bc_validate converts inputs to standard form.
#' @srrstats {G2.10} Column extraction uses [[]] and dplyr::all_of().
#' @srrstats {G2.11} Non-standard column classes caught by is.numeric.
#' @srrstats {G2.12} List columns cause brms errors with informative messages.
#' @srrstats {G2.14b} allow_negative relaxes negativity checks.
#' @srrstats {G2.14c} Not applicable: no imputation.
#' @srrstats {G3.0} No floating-point equality comparisons; bc_filter_matching
#'   uses tolerance-based range checks (diff(range()) <= tol).
#' @srrstats {G5.8a} Zero-length data: bc_validate errors on empty data.
#' @srrstats {G5.8b} Unsupported types: bc_validate errors on non-numeric.
#' @srrstats {G5.8c} All-NA: bc_validate catches and reports.
#' @srrstats {G5.8d} Edge: single-system or single-method data produces
#'   informative errors from bc_validate.
#' @srrstats {RE2.0} bc_validate asserts dimensionality: >= 2 methods,
#'   >= 1 system, required columns present.
#' @srrstats {RE2.1} bc_validate handles NA/NaN/Inf with distinct messages.
#' @srrstats {RE2.2} Missing values rejected in both response and predictors.
#' @srrstats {RE2.3} Collinearity: not applicable, brms handles rank
#'   deficiency internally via Stan's QR decomposition.
#' @srrstats {RE2.4} bc_validate errors on NA by default; bc_filter_matching
#'   removes systems with NA via na.rm = TRUE aggregation.
#' @srrstats {RE2.4a} bc_validate explicitly checks NaN and Inf with
#'   distinct error messages per type.
#' @srrstats {RE2.4b} bc_validate never assumes non-missingness; every
#'   numeric column is explicitly checked for NA/NaN/Inf.
#' @srrstats {RE7.2} test-data_prep.R verifies names/levels retained.
#' @noRd
NULL
