# Run posterior predictive check suite

Generates a set of posterior predictive check plots for visual model
assessment.

## Usage

``` r
bc_pp_check(model, group_col = "method", ndraws = 50)
```

## Arguments

- model:

  A `brmsfit` object.

- group_col:

  Column name for grouped checks (default `"method"`).

- ndraws:

  Number of posterior draws for density overlay (default 50).

## Value

A named list of ggplot objects.

## Examples

``` r
if (FALSE) { # \dontrun{
model <- bc_fit(bc_simulate_benchmark(), response = "count")
plots <- bc_pp_check(model)
} # }
```
