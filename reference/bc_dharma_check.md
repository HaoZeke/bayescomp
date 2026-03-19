# DHARMa residual diagnostics for brms models

Produces simulated residual diagnostics using the DHARMa framework.
Checks for uniformity (QQ plot), overdispersion, and outliers. Requires
the `DHARMa` package.

## Usage

``` r
bc_dharma_check(model, n_sim = 250)
```

## Arguments

- model:

  A `brmsfit` object.

- n_sim:

  Number of simulations for residual calculation (default 250).

## Value

A DHARMa simulation object (invisibly). Produces diagnostic plots as a
side effect.

## Examples

``` r
if (FALSE) { # \dontrun{
model <- bc_fit(bc_simulate_benchmark(), response = "count")
bc_dharma_check(model)
} # }
```
