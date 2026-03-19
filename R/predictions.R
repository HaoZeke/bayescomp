#' @srrstats {BS5.2} bc_epred_draws caches posterior predictions
#' Cached posterior expected predictions
#'
#' Computes or loads cached posterior expected predictions using
#' [tidybayes::add_epred_draws()]. Results are saved to a zstd-compressed
#' RDS file for fast reloading.
#'
#' @param model A `brmsfit` object.
#' @param newdata Data frame for predictions.
#' @param file Cache file path (should end in `.rds`). If `NULL`, no caching.
#' @param ndraws Number of posterior draws (default `NULL` for all).
#' @param ... Additional arguments passed to [tidybayes::add_epred_draws()].
#' @return A grouped data frame from `tidybayes::add_epred_draws()`.
#' @examples
#' \dontrun{
#' data <- bc_simulate_benchmark(n_systems = 20)
#' model <- bc_fit(data, response = "count")
#' draws <- bc_epred_draws(model, newdata = data)
#' }
#' @export
bc_epred_draws <- function(model, newdata, file = NULL, ndraws = NULL, ...) {
  if (!inherits(model, "brmsfit")) {
    cli::cli_abort("{.arg model} must be a brmsfit object.")
  }
  if (!is.data.frame(newdata)) {
    cli::cli_abort("{.arg newdata} must be a data frame.")
  }

  # Try loading from cache
  if (!is.null(file) && file.exists(file)) {
    cli::cli_inform("Loading cached predictions from {.file {file}}")
    con <- archive::file_read(file = file)
    result <- readRDS(con)
    close(con)
    return(result)
  }

  # Compute
  cli::cli_inform("Computing posterior predictions (this may take a while)...")
  args <- list(object = model, newdata = newdata)
  if (!is.null(ndraws)) args$ndraws <- ndraws
  args <- c(args, list(...))
  result <- do.call(tidybayes::add_epred_draws, args)

  # Save to cache
  if (!is.null(file)) {
    dir <- dirname(file)
    if (!dir.exists(dir)) dir.create(dir, recursive = TRUE)

    cli::cli_inform("Saving predictions to {.file {file}}")
    con <- archive::file_write(file = file, filter = "zstd",
                                options = "compression-level=10")
    saveRDS(result, con)
    close(con)
  }

  result
}
