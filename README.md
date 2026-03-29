# bayescomp

<!-- badges: start -->
[![R-CMD-check](https://github.com/HaoZeke/bayescomp/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/HaoZeke/bayescomp/actions/workflows/R-CMD-check.yaml)
[![pkgcheck](https://github.com/HaoZeke/bayescomp/actions/workflows/pkgcheck.yaml/badge.svg)](https://github.com/HaoZeke/bayescomp/actions/workflows/pkgcheck.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![Codecov](https://codecov.io/gh/HaoZeke/bayescomp/branch/main/graph/badge.svg)](https://codecov.io/gh/HaoZeke/bayescomp)
[![Project Status: WIP](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)
<!-- badges: end -->

Bayesian hierarchical comparison of computational method benchmarks.

bayescomp wraps [brms](https://paul-buerkner.github.io/brms/) with
opinionated defaults for the (system x method) crossed design common in
computational chemistry, physics, and engineering benchmarks. It fits
negative binomial (count data), Gamma (timing), Bernoulli (success), and
Student-t (signed errors) models with random intercepts per test system,
and provides publication-quality diagnostics and effect summaries.

## Installation

```r
# install.packages("remotes")
remotes::install_github("HaoZeke/bayescomp")
```

bayescomp requires a working
[cmdstanr](https://mc-stan.org/cmdstanr/) installation for model fitting.

## Quick example

```r
library(bayescomp)

# Simulate benchmark data (20 systems, 2 methods)
data <- bc_simulate_benchmark(n_systems = 20, n_methods = 2,
                               true_effect = log(0.5))

# Fit a Bayesian hierarchical model
model <- bc_fit(data, response = "count")

# One-call summary report
bc_report(model)

# Publication plots
bc_plot_conditional(model, effects = "method")
bc_plot_dumbbell(data)
bc_plot_cactus(data)
```

## What it does

Given a CSV of benchmark results (systems as rows, method-specific
columns), bayescomp:

1. **Reads and validates** the data, checking for NA/NaN/Inf and
   guiding you toward the correct response family
2. **Fits a hierarchical model** with random intercepts per system,
   choosing negative binomial over Gaussian for count data (and warning
   you if you try Gaussian)
3. **Runs diagnostics** automatically: convergence checks, shape
   parameter reporting, LOO-CV
4. **Extracts effects** on the response scale: multiplicative factors
   and percentage changes with credible intervals
5. **Generates plots**: conditional effects, posterior predictive checks,
   Pareto-k diagnostics, dumbbell comparisons, performance profiles

## Why not just use brms directly?

You can. bayescomp adds value through:

- **Family selection guardrails**: warns against Gaussian for count data
- **Sensible defaults**: weakly informative priors calibrated for N=20-100
  benchmark sets: `normal(0, 1)` on fixed effects, `exponential(1)` on
  random effect SD, `student_t(3, 0, 2.5)` on intercept (see
  `bc_default_priors()`)
- **Right-censoring support**: runs hitting iteration limits are
  right-censored, not treated as observed counts
- **One-call workflow**: `bc_read_benchmark() |> bc_pivot_long() |> bc_fit()`
- **targets integration**: every pipeline stage is independently cacheable

## Vignettes

- [Getting Started](vignettes/bayescomp.Rmd)
- [NEB Case Study](vignettes/neb-case-study.Rmd)
- [Dimer Rotation Case Study](vignettes/dimer-case-study.Rmd)
- [Model Selection Guide](vignettes/model-selection.Rmd)

## License

GPL (>= 3)
