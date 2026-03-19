# Shape parameter posterior density comparison

For negative binomial models with a shape submodel, plots the posterior
density of the shape parameter for each method level.

## Usage

``` r
bc_plot_shape(model, method_col = "method", colors = NULL)
```

## Arguments

- model:

  A `brmsfit` object with `shape ~ method`.

- method_col:

  Name of the method column (default `"method"`).

- colors:

  Named character vector of method colors.

## Value

A ggplot object.

## Examples

``` r
if (FALSE) { # \dontrun{
model <- bc_fit(bc_simulate_benchmark(), response = "count",
  model_shape = TRUE)
bc_plot_shape(model)
} # }
```
