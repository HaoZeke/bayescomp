#' bayescomp color palettes
#'
#' Named color palettes for benchmark comparison plots. The `bayescomp`
#' palette is designed for colorblind accessibility.
#'
#' @name bayescomp_colors
#' @format Named character vectors.
NULL

#' @rdname bayescomp_colors
#' @export
bc_colors <- c(
  teal      = "#004D40",
  green     = "#009E73",
  sky       = "#1E88E5",
  purple    = "#5E35B1",
  magenta   = "#D81B60",
  coral     = "#FF655D",
  orange    = "#E69F00",
  sunshine  = "#F1DB4B"
)

#' @rdname bayescomp_colors
#' @export
bc_colors_discrete <- c(
  coral     = "#FF655D",
  sky       = "#1E88E5",
  green     = "#009E73",
  sunshine  = "#F1DB4B",
  purple    = "#5E35B1",
  orange    = "#E69F00",
  magenta   = "#D81B60",
  teal      = "#004D40"
)

bc_pal_discrete <- function(reverse = FALSE) {
  cols <- unname(bc_colors_discrete)
  if (reverse) cols <- rev(cols)
  function(n) {
    rep(cols, length.out = n)
  }
}

#' Discrete color scale for bayescomp
#'
#' @param ... Arguments passed to [ggplot2::discrete_scale()].
#' @param reverse Logical. Reverse palette order?
#' @return A ggplot2 scale.
#' @examples
#' library(ggplot2)
#' data <- bc_simulate_benchmark(n_systems = 10, n_methods = 3)
#' ggplot(data, aes(system_id, count, color = method)) +
#'   geom_point() + scale_color_bayescomp()
#' @export
scale_color_bayescomp <- function(..., reverse = FALSE) {
  ggplot2::discrete_scale(
    aesthetics = "colour",
    palette = bc_pal_discrete(reverse = reverse),
    ...
  )
}

#' @rdname scale_color_bayescomp
#' @export
scale_colour_bayescomp <- scale_color_bayescomp

#' Fill scale for bayescomp
#'
#' @inheritParams scale_color_bayescomp
#' @return A ggplot2 scale.
#' @examples
#' library(ggplot2)
#' data <- bc_simulate_benchmark(n_systems = 10, n_methods = 3)
#' ggplot(data, aes(method, count, fill = method)) +
#'   geom_boxplot() + scale_fill_bayescomp()
#' @export
scale_fill_bayescomp <- function(..., reverse = FALSE) {
  ggplot2::discrete_scale(
    aesthetics = "fill",
    palette = bc_pal_discrete(reverse = reverse),
    ...
  )
}

#' Publication theme for bayescomp
#'
#' A clean ggplot2 theme based on ggthemes::theme_foundation with
#' Atkinson Hyperlegible font (when available).
#'
#' @param base_size Base font size (default 14).
#' @param base_family Font family (default `"Atkinson Hyperlegible"`).
#'   Falls back to `"sans"` if not available.
#' @return A ggplot2 theme.
#' @examples
#' library(ggplot2)
#' ggplot(mtcars, aes(wt, mpg)) + geom_point() + theme_bayescomp()
#' @export
theme_bayescomp <- function(base_size = 14, base_family = "sans") {
  # Try Atkinson Hyperlegible if showtext is available
  if (requireNamespace("sysfonts", quietly = TRUE) &&
      requireNamespace("showtext", quietly = TRUE)) {
    if (!"Atkinson Hyperlegible" %in% sysfonts::font_families()) {
      tryCatch({
        sysfonts::font_add_google("Atkinson Hyperlegible", "Atkinson Hyperlegible")
        showtext::showtext_auto()
        base_family <- "Atkinson Hyperlegible"
      }, error = function(e) NULL)
    } else {
      base_family <- "Atkinson Hyperlegible"
    }
  }

  base_theme <- if (requireNamespace("ggthemes", quietly = TRUE)) {
    ggthemes::theme_foundation(base_size = base_size, base_family = base_family)
  } else {
    ggplot2::theme_grey(base_size = base_size, base_family = base_family)
  }

  base_theme +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = ggplot2::rel(1.2),
                                         hjust = 0.5),
      text = ggplot2::element_text(),
      panel.background = ggplot2::element_rect(colour = NA, fill = "#FFFFFF"),
      plot.background = ggplot2::element_rect(colour = NA, fill = "#FFFFFF"),
      panel.border = ggplot2::element_rect(colour = "black", fill = NA,
                                            linewidth = 0.8),
      axis.title = ggplot2::element_text(face = "bold", size = ggplot2::rel(1.0)),
      axis.title.y = ggplot2::element_text(angle = 90, vjust = 2),
      axis.title.x = ggplot2::element_text(vjust = -0.2),
      axis.text = ggplot2::element_text(size = ggplot2::rel(0.9)),
      axis.line = ggplot2::element_line(colour = "black"),
      panel.grid.major = ggplot2::element_line(colour = "#e6e3dd"),
      panel.grid.minor = ggplot2::element_blank(),
      legend.background = ggplot2::element_rect(fill = "#FFFFFF", colour = NA),
      legend.key = ggplot2::element_rect(colour = NA, fill = "#FFFFFF"),
      legend.position = "right",
      legend.title = ggplot2::element_text(face = "italic"),
      strip.background = ggplot2::element_rect(colour = "#FFFFFF", fill = "#FFFFFF"),
      strip.text = ggplot2::element_text(face = "bold")
    )
}
