# LOO-PIT QQ plot

Generates a LOO-PIT (Probability Integral Transform) QQ plot for
assessing model calibration.

## Usage

``` r
bc_plot_loo_pit(model, loo_result, y)
```

## Arguments

- model:

  A `brmsfit` object.

- loo_result:

  A `loo` object from
  [`bc_loo()`](https://haozeke.github.io/bayescomp/reference/bc_loo.md).

- y:

  Observed response vector.

## Value

A ggplot object.

## Examples

``` r
if (FALSE) { # \dontrun{
model <- bc_fit(bc_simulate_benchmark(), response = "count")
loo_result <- bc_loo(model)
bc_plot_loo_pit(model, loo_result, y = model$data$count)
} # }
```
