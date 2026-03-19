# Posterior predictive check plot

Posterior predictive check plot

## Usage

``` r
bc_plot_pp(model, ndraws = 50, type = "dens_overlay")
```

## Arguments

- model:

  A `brmsfit` object.

- ndraws:

  Number of posterior draws (default 50).

- type:

  Type of pp_check (default `"dens_overlay"`).

## Value

A ggplot object.

## Examples

``` r
if (FALSE) { # \dontrun{
model <- bc_fit(bc_simulate_benchmark(), response = "count")
bc_plot_pp(model)
} # }
```
