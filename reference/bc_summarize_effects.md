# Summarize treatment effects on the response scale

Extracts posterior draws for the method effect and transforms them to
the response scale (multiplicative factor and percentage change).

## Usage

``` r
bc_summarize_effects(model, width = 0.95)
```

## Arguments

- model:

  A `brmsfit` object.

- width:

  Credible interval width (default 0.95).

## Value

A tibble with columns: effect_type, median, lower, upper, formatted. For
log-link models: baseline expected value, multiplicative factors,
percentage changes. For logit-link: baseline probability, odds ratios.
For identity-link: baseline value, additive effects.

## Examples

``` r
if (FALSE) { # \dontrun{
model <- bc_fit(bc_simulate_benchmark(), response = "count")
bc_summarize_effects(model)
} # }
```
