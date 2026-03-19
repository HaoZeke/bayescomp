#' @importFrom rlang .data %||%
#' @keywords internal
"_PACKAGE"

# brms prior DSL uses non-standard evaluation for these
# Suppress R CMD check NOTEs about undefined globals
utils::globalVariables(c(
  "normal", "exponential", "student_t", ":="
))
