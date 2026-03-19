# Pareto-k diagnostic plot

Plots the Pareto-k values from LOO-CV, highlighting observations with
high influence (k \> 0.7) or marginal influence (k \> 0.5). Based on the
diagnostic framework in Vehtari, Gelman, and Gabry (2017).

## Usage

``` r
bc_plot_pareto_k(loo_result, label_threshold = 0.7)
```

## Arguments

- loo_result:

  A `loo` object from
  [`bc_loo()`](https://haozeke.github.io/bayescomp/reference/bc_loo.md).

- label_threshold:

  Threshold above which to label points with their observation index
  (default 0.7).

## Value

A ggplot object.

## Examples

``` r
if (FALSE) { # \dontrun{
model <- bc_fit(bc_simulate_benchmark(), response = "count")
loo_result <- bc_loo(model)
bc_plot_pareto_k(loo_result)
} # }
```
