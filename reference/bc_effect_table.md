# Generate a publication-ready effect summary table

Formats the output of
[`bc_summarize_effects()`](https://haozeke.github.io/bayescomp/reference/bc_summarize_effects.md)
for inclusion in manuscripts. Percentage changes are formatted with `%`
signs and credible intervals are in brackets.

## Usage

``` r
bc_effect_table(model, ...)
```

## Arguments

- model:

  A `brmsfit` object.

- ...:

  Arguments passed to
  [`bc_summarize_effects()`](https://haozeke.github.io/bayescomp/reference/bc_summarize_effects.md).

## Value

A data frame with columns: Effect, Median, `95% CrI`.

## Examples

``` r
if (FALSE) { # \dontrun{
model <- bc_fit(bc_simulate_benchmark(), response = "count")
bc_effect_table(model)
} # }
```
