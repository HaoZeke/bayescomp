# Trace plots for MCMC diagnostics

Generates trace plots for key model parameters showing chain mixing and
convergence. Wraps
[`bayesplot::mcmc_trace()`](https://mc-stan.org/bayesplot/reference/MCMC-traces.html)
with the bayescomp theme.

## Usage

``` r
bc_plot_trace(model, pars = NULL)
```

## Arguments

- model:

  A `brmsfit` object.

- pars:

  Character vector of parameter names to plot. If `NULL`, plots the
  intercept, method effects, and random effect SD.

## Value

A ggplot object.

## Examples

``` r
if (FALSE) { # \dontrun{
model <- bc_fit(bc_simulate_benchmark(), response = "count")
bc_plot_trace(model)
} # }
```
