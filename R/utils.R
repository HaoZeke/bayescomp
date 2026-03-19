#' @srrstats {G2.10} Column extraction uses [[]] and dplyr::all_of() for
#'   safe extraction regardless of tibble/data.frame semantics.
#' @srrstats {G2.6} bc_validate() checks are class-agnostic (work on
#'   data.frame, tibble, data.table).
#' @srrstats {G5.2} All errors use cli::cli_abort() with structured messages.
#' @srrstats {G5.2a} Each cli message has unique template text.
#' @importFrom rlang .data %||%
#' @keywords internal
"_PACKAGE"

# brms prior DSL uses non-standard evaluation for these
# Suppress R CMD check NOTEs about undefined globals
utils::globalVariables(c(
  "normal", "exponential", "student_t", ":="
))
