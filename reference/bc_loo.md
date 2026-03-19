# Compute LOO-CV with optional reloo

Calls the brms LOO method with Pareto-k diagnostic reporting. Optionally
refits for observations with high Pareto-k values.

## Usage

``` r
bc_loo(model, reloo = TRUE)
```

## Arguments

- model:

  A `brmsfit` object.

- reloo:

  Logical. If `TRUE`, refits for observations with Pareto k \> 0.7
  (default `TRUE`).

## Value

A `loo` object with attached summary.

## Examples

``` r
if (FALSE) { # \dontrun{
model <- bc_fit(bc_simulate_benchmark(), response = "count")
loo_result <- bc_loo(model)
} # }
```
