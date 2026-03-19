# Pairwise method contrasts

Computes all pairwise comparisons between method levels using posterior
draws. Requires the `marginaleffects` package.

## Usage

``` r
bc_pairwise_contrasts(model, method_col = "method", width = 0.95)
```

## Arguments

- model:

  A `brmsfit` object.

- method_col:

  Name of the method column (default `"method"`).

- width:

  Credible interval width (default 0.95).

## Value

A tibble with columns: contrast, estimate, lower, upper, formatted.

## Examples

``` r
if (FALSE) { # \dontrun{
model <- bc_fit(bc_simulate_benchmark(), response = "count")
bc_pairwise_contrasts(model)
} # }
```
