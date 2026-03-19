# Conditional effects plot with raw data overlay

Generates a publication-quality plot of conditional effects from a
fitted brms model, with the raw benchmark data overlaid as jittered
points.

## Usage

``` r
bc_plot_conditional(
  model,
  effects,
  data = NULL,
  response_col = "count",
  covariate_col = NULL,
  method_col = "method",
  log_y = TRUE,
  show_extrapolation = FALSE,
  colors = NULL
)
```

## Arguments

- model:

  A `brmsfit` object.

- effects:

  Character string specifying the conditional effects (e.g.,
  `"RMSD_Init_Final:method"`).

- data:

  Original data for raw point overlay (optional).

- response_col:

  Response variable name in `data` for overlay.

- covariate_col:

  Name of the covariate column for extrapolation boundary detection
  (optional). Required when `show_extrapolation = TRUE`.

- method_col:

  Name of the method column in `data` (default `"method"`).

- log_y:

  Logical. Use log scale on y-axis? (default `TRUE`).

- show_extrapolation:

  Logical. If `TRUE`, marks the boundary between interpolation (observed
  range) and extrapolation (beyond observed range) per method. Requires
  `data` and `covariate_col`.

- colors:

  Named character vector of method colors. If `NULL`, uses the bayescomp
  palette.

## Value

A ggplot object.

## Details

When `show_extrapolation = TRUE` and original `data` is provided, the
plot marks the maximum observed covariate value per method with a
vertical dashed line and switches the prediction line from solid to
dashed beyond the observed range. This is important when ML-enhanced
methods converge with far fewer evaluations than classical baselines,
leaving no observed data in the high-effort regime (see Goswami 2025,
arXiv:2510.21368, Section 6.4.1).

## Examples

``` r
if (FALSE) { # \dontrun{
model <- bc_fit(bc_simulate_benchmark(), response = "count")
bc_plot_conditional(model, effects = "method")
} # }
```
