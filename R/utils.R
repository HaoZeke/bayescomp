#' @importFrom rlang .data
#' @keywords internal
"_PACKAGE"

# Re-export pipe for convenience
#' @importFrom dplyr %>%
#' @export
dplyr::`%>%`

# Null-coalescing operator
`%||%` <- function(x, y) if (is.null(x)) y else x
