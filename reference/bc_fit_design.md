# Fit a Bayesian benchmark model with a custom formula

Full brms formula passthrough for factorial designs, interactions, and
custom random effects. Use when
[`bc_fit()`](https://haozeke.github.io/bayescomp/reference/bc_fit.md) is
too restrictive (e.g., `algorithm * rotation_removal` interactions or
`(1 | mol_id:spin)`).

## Usage

``` r
bc_fit_design(
  data,
  formula,
  family = NULL,
  prior = NULL,
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

  Long-format benchmark data.

- formula:

  A
  [`brms::bf()`](https://paulbuerkner.com/brms/reference/brmsformula.html)
  formula object.

- family:

  A brms family object. If `NULL`, auto-detected from the response
  variable in the formula.

- prior:

  A `brmsprior` object. If `NULL`, uses
  [`bc_default_priors()`](https://haozeke.github.io/bayescomp/reference/bc_default_priors.md).

- cens_col:

  Name of a binary censoring column (optional).

- diagnostics:

  Logical. Run convergence diagnostics after fitting?

- chains, iter, warmup, cores, seed, backend, file, adapt_delta,
  max_treedepth:

  Passed to
  [`brms::brm()`](https://paulbuerkner.com/brms/reference/brm.html).

- ...:

  Additional arguments passed to
  [`brms::brm()`](https://paulbuerkner.com/brms/reference/brm.html).

## Value

A `brmsfit` object.

## Examples

``` r
if (FALSE) { # \dontrun{
data <- bc_simulate_benchmark(n_systems = 20)
formula <- brms::bf(count ~ method + (1 | system_id))
model <- bc_fit_design(data, formula = formula)
} # }
```
