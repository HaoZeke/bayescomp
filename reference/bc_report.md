# Generate a complete analysis report

Produces a formatted text summary combining convergence diagnostics,
effect estimates, overdispersion assessment, and LOO-CV results from a
fitted benchmark model. Designed to be copy-pasted into a paper draft or
shared with collaborators.

## Usage

``` r
bc_report(model, width = 0.95, loo = TRUE)
```

## Arguments

- model:

  A `brmsfit` object from
  [`bc_fit()`](https://haozeke.github.io/bayescomp/reference/bc_fit.md)
  or
  [`bc_fit_design()`](https://haozeke.github.io/bayescomp/reference/bc_fit_design.md).

- width:

  Credible interval width (default 0.95).

- loo:

  Logical. Run LOO-CV? (default `TRUE`). Set `FALSE` to skip the
  expensive computation.

## Value

Invisibly returns a list with components: convergence, effects,
loo_result. Prints a formatted report as a side effect.

## Examples

``` r
if (FALSE) { # \dontrun{
model <- bc_fit(bc_simulate_benchmark(), response = "count")
bc_report(model)
} # }
```
