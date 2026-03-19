# Check convergence diagnostics for a brmsfit

Examines Rhat and effective sample size (ESS) for all parameters and
returns a structured summary with pass/fail flags.

## Usage

``` r
bc_check_convergence(model, max_rhat = 1.01, min_ess = 400)
```

## Arguments

- model:

  A `brmsfit` object.

- max_rhat:

  Maximum acceptable Rhat (default 1.01).

- min_ess:

  Minimum acceptable bulk ESS (default 400).

## Value

A list with components:

- passed:

  Logical. `TRUE` if all diagnostics pass.

- summary:

  Data frame from
  [`posterior::summarise_draws()`](https://mc-stan.org/posterior/reference/draws_summary.html)
  with rhat, ess_bulk, ess_tail per parameter.

- max_rhat:

  Observed maximum Rhat.

- min_ess:

  Observed minimum bulk ESS.

- problems:

  Character vector describing any issues.

## Examples

``` r
if (FALSE) { # \dontrun{
model <- bc_fit(bc_simulate_benchmark(), response = "count")
bc_check_convergence(model)
} # }
```
