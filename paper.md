---
title: 'bayescomp: Bayesian Hierarchical Comparison of Computational Method Benchmarks in R'
tags:
  - R
  - Bayesian statistics
  - benchmarking
  - computational chemistry
  - hierarchical models
  - brms
authors:
  - name: Rohit Goswami
    orcid: 0000-0002-2393-8056
    affiliation: 1
affiliations:
  - name: Laboratory of Computational Science and Modeling, EPFL, Switzerland
    index: 1
date: 18 March 2026
bibliography: paper.bib
---

# Summary

Comparing computational methods on shared test problems is central to
method development in computational chemistry, materials science, and
related fields. Standard practice reduces per-system results to mean
ratios or median speedups, discarding the hierarchical structure of the
data and providing no uncertainty quantification. `bayescomp` is an R
package that fits Bayesian hierarchical models to benchmark comparisons,
treating each test system as a random effect and selecting the
appropriate response family (negative binomial for counts, Gamma for
timing, Bernoulli for convergence success, Student-t for signed errors)
with opinionated guardrails against common misspecifications such as
applying Gaussian models to count data.

# Statement of need

Computational benchmarks produce count data (force evaluations, SCF
iterations), wall-clock times, and binary convergence outcomes across
tens to hundreds of test systems. A survey of the Journal of Chemical
Theory and Computation (JCTC) and Journal of Chemical Physics (JCP)
confirms that formal statistical testing is essentially absent from this
literature: results are reported as tables of raw numbers with mean or
median summary rows.

This practice has three problems. First, it ignores the paired
structure: each test system has its own baseline difficulty, so method
differences are confounded with test-set composition. Second, count data
is overdispersed (variance exceeds the mean, often by an order of
magnitude), violating Gaussian assumptions. Third, small benchmark sets
(N = 20--50 systems) make frequentist p-values unreliable and point
estimates noisy.

`bayescomp` addresses all three by wrapping `brms` [@Buerkner2017brms]
with domain-appropriate defaults. The two-function API ---
`bc_fit()` for simple A-vs-B comparisons and `bc_fit_design()` for
factorial designs --- auto-detects the response family, sets weakly
informative priors, handles right-censored observations (runs hitting
iteration limits), and reports convergence diagnostics automatically.
The package integrates with `targets` [@Landau2021targets] for
reproducible pipelines and provides 15 publication-quality plot types
including dumbbell comparisons, performance profiles, and posterior
predictive checks following the Bayesian workflow recommendations of
@Gelman2020workflow and @Gabry2019visualization.

# Key features

- **Opinionated family selection**: auto-detects negative
  binomial/Gamma/Bernoulli/Student-t from data type, warns against
  Gaussian misuse on count data
- **Right-censoring**: runs hitting iteration limits are treated as
  censored observations via `brms | cens()`, preventing downward bias
- **Two entry points**: `bc_fit()` for the common case (method as
  factor), `bc_fit_design()` for full `brms::bf()` formula passthrough
- **Pairwise contrasts**: `bc_pairwise_contrasts()` wraps
  `marginaleffects` for >2 method comparisons
- **Simulation**: `bc_simulate_benchmark()` for power analysis and
  parameter recovery testing
- **Over 40 exported functions** covering data ingestion, validation, model
  fitting, diagnostics, effect extraction, and visualization

# Example

The package ships with data from the Baker transition-state benchmark
(24 molecular systems, CI-NEB vs OCI-NEB). A complete analysis:

```r
library(bayescomp)
data <- bc_read_benchmark(
  system.file("extdata", "baker_bench.csv", package = "bayescomp"),
  format = "wide", method_suffixes = c("CINEB", "MMF"))
long <- bc_pivot_long(data, method_pattern = "_(CINEB|MMF)$",
                       method_levels = c("CINEB", "MMF"))
model <- bc_fit(long, response = "count",
                 spline_by_method = "RMSD_Init_Final",
                 model_shape = TRUE)
bc_report(model)
```

This yields a 46% reduction in gradient evaluations (95% CrI: 37--55%)
for OCI-NEB relative to CI-NEB, with full posterior uncertainty
quantification [@Goswami2025dimer].

# Acknowledgements

This work was supported by EPFL. The methodology follows
@Goswami2025dimer and @Goswami2025thesis.

# References
