# Forest plot of method effects

Forest plot of method effects

## Usage

``` r
bc_plot_forest(model, method_col = "method", colors = NULL)
```

## Arguments

- model:

  A `brmsfit` object.

- method_col:

  Name of the method column (default `"method"`).

- colors:

  Named character vector of method colors.

## Value

A ggplot object.

## Examples

``` r
if (FALSE) { # \dontrun{
model <- bc_fit(bc_simulate_benchmark(), response = "count")
bc_plot_forest(model)
} # }
```
