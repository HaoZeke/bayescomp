#' Create a targets-compatible benchmark analysis pipeline
#'
#' Returns a list of target objects that implement the full bayescomp
#' workflow: read data, pivot, fit model, run diagnostics, extract effects,
#' and generate plots.
#'
#' This is designed to be called inside `_targets.R` as:
#' ```r
#' library(targets)
#' library(bayescomp)
#' bc_tar_pipeline("inst/extdata/baker_bench.csv", ...)
#' ```
#'
#' @param data_path Path to benchmark CSV file.
#' @param method_suffixes Character vector of method suffixes for wide format.
#' @param method_levels Factor levels for method column.
#' @param method_pattern Regex for pivot_longer.
#' @param response Response variable name after pivoting.
#' @param system_col System column name in raw data.
#' @param count_col Count column prefix in raw data.
#' @param time_col Time column prefix (optional).
#' @param success_col Success/termination column prefix (optional).
#' @param spline_by_method Covariate for method-varying spline (optional).
#' @param model_shape Model dispersion by method?
#' @param output_dir Directory for output figures.
#' @param model_file Cache path for fitted model.
#' @param ... Additional arguments passed to [bc_fit()].
#' @return A list of `tar_target` objects, or `NULL` if targets is not
#'   available.
#' @examples
#' \dontrun{
#' library(targets)
#' bc_tar_pipeline("data/bench.csv",
#'   method_suffixes = c("A", "B"), response = "count")
#' }
#' @export
bc_tar_pipeline <- function(data_path,
                            method_suffixes,
                            method_levels = method_suffixes,
                            method_pattern = NULL,
                            response = "count",
                            system_col = "System",
                            count_col = "Calls",
                            time_col = NULL,
                            success_col = NULL,
                            spline_by_method = NULL,
                            model_shape = FALSE,
                            output_dir = "figures",
                            model_file = "data/models/bayescomp_model",
                            ...) {
  if (!requireNamespace("targets", quietly = TRUE)) {
    cli::cli_abort("Package {.pkg targets} is required for pipeline helpers.")
    return(NULL)
  }

  if (is.null(method_pattern)) {
    method_pattern <- paste0("_(", paste(method_suffixes, collapse = "|"), ")$")
  }

  list(
    targets::tar_target_raw("bench_raw", substitute(
      bc_read_benchmark(
        path = data_path_,
        format = "wide",
        method_suffixes = method_suffixes_,
        system_col = system_col_,
        count_col = count_col_,
        time_col = time_col_,
        success_col = success_col_
      ),
      list(data_path_ = data_path, method_suffixes_ = method_suffixes,
           system_col_ = system_col, count_col_ = count_col,
           time_col_ = time_col, success_col_ = success_col)
    )),

    targets::tar_target_raw("bench_long", substitute(
      bc_pivot_long(
        bench_raw,
        method_pattern = method_pattern_,
        method_levels = method_levels_
      ),
      list(method_pattern_ = method_pattern, method_levels_ = method_levels)
    )),

    targets::tar_target_raw("model_fit", substitute(
      bc_fit(
        bench_long,
        response = response_,
        spline_by_method = spline_by_method_,
        model_shape = model_shape_,
        file = model_file_
      ),
      list(response_ = response, spline_by_method_ = spline_by_method,
           model_shape_ = model_shape, model_file_ = model_file)
    )),

    targets::tar_target_raw("convergence", quote(
      bc_check_convergence(model_fit)
    )),

    targets::tar_target_raw("loo_result", quote(
      bc_loo(model_fit)
    )),

    targets::tar_target_raw("effect_summary", quote(
      bc_summarize_effects(model_fit)
    )),

    targets::tar_target_raw("effect_table", quote(
      bc_effect_table(model_fit)
    ))
  )
}
