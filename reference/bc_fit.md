# Fit a Bayesian benchmark comparison model

Wraps [`brms::brm()`](https://paulbuerkner.com/brms/reference/brm.html)
with sensible defaults for comparing computational methods on shared
benchmark problems. Constructs the formula from column names and
optional covariates, selects the family if not provided, and uses weakly
informative priors by default.

## Usage

``` r
bc_fit(
  data,
  response = "count",
  method_col = "method",
  system_col = "system_id",
  covariates = NULL,
  spline_by_method = NULL,
  family = NULL,
  prior = NULL,
  model_shape = FALSE,
  cens_col = NULL,
  diagnostics = TRUE,
  chains = 4,
  iter = 4000,
  warmup = 1000,
  cores = 4,
  seed = 1995,
  backend = NULL,
  file = NULL,
  adapt_delta = 0.99,
  max_treedepth = 12,
  ...
)
```

## Arguments

- data:

  Long-format benchmark data (as from
  [`bc_pivot_long()`](https://haozeke.github.io/bayescomp/reference/bc_pivot_long.md)).

- response:

  Name of the response variable (default `"count"`).

- method_col:

  Name of the method column (default `"method"`).

- system_col:

  Name of the system/grouping column (default `"system_id"`).

- covariates:

  Character vector of covariate names for fixed effects (optional).

- spline_by_method:

  Name of a covariate for a method-varying thin plate spline (optional).
  Adds `s(covariate, by = method, k = 3)`.

- family:

  A brms family object. If `NULL`, auto-detected via
  [`bc_suggest_family()`](https://haozeke.github.io/bayescomp/reference/bc_suggest_family.md).

- prior:

  A `brmsprior` object. If `NULL`, uses
  [`bc_default_priors()`](https://haozeke.github.io/bayescomp/reference/bc_default_priors.md).

- model_shape:

  Logical. If `TRUE`, models the dispersion parameter as a function of
  method (relevant for negative binomial).

- cens_col:

  Name of a binary censoring column (0 = observed, 1 = right-censored).
  If provided, adds `| cens(cens_col)` to the brms formula. Use with
  [`bc_pivot_long()`](https://haozeke.github.io/bayescomp/reference/bc_pivot_long.md)
  `cens_value` parameter.

- diagnostics:

  Logical. If `TRUE` (default), runs convergence diagnostics after
  fitting and reports shape parameter for negbinomial.

- chains:

  Number of MCMC chains (default 4).

- iter:

  Total iterations per chain (default 4000).

- warmup:

  Warmup iterations per chain (default 1000).

- cores:

  Number of cores for parallel chains (default 4).

- seed:

  Random seed for reproducibility.

- backend:

  Stan backend (default `"cmdstanr"`).

- file:

  Cache file path for the fitted model (optional).

- adapt_delta:

  Target acceptance rate (default 0.99).

- max_treedepth:

  Maximum tree depth (default 12).

- ...:

  Additional arguments passed to
  [`brms::brm()`](https://paulbuerkner.com/brms/reference/brm.html).

## Value

A `brmsfit` object.

## Examples

``` r
if (FALSE) { # \dontrun{
data <- bc_simulate_benchmark(n_systems = 20)
model <- bc_fit(data, response = "count")
} # }
```
