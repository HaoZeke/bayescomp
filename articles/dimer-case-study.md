# Multi-Method Comparison with Dimer Rotation

## Overview

This vignette analyses the dimer rotation benchmark, which compares four
optimization methods for the initial dimer rotation step in
transition-state searches. The data set has three response variables
(force/energy call counts, wall-clock time, and binary success), making
it a good test case for
[`bc_fit_suite()`](https://haozeke.github.io/bayescomp/reference/bc_fit_suite.md).

It also demonstrates two features that go beyond the basic
[`bc_fit()`](https://haozeke.github.io/bayescomp/reference/bc_fit.md)
workflow:

1.  [`bc_fit_design()`](https://haozeke.github.io/bayescomp/reference/bc_fit_design.md)
    for factorial designs with interaction terms
2.  [`bc_pairwise_contrasts()`](https://haozeke.github.io/bayescomp/reference/bc_pairwise_contrasts.md)
    for all-pairs comparisons when there are more than two methods

## Data

The dimer rotation benchmark ships with bayescomp. Unlike the Baker
data, it is already in long format: one row per system-method
observation.

``` r
library(bayescomp)
library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union
```

``` r
path <- system.file("extdata", "idrot_bench.csv", package = "bayescomp")

bench <- bc_read_benchmark(
  path,
  format     = "long",
  system_col = "system_id"
)

head(bench)
#> # A tibble: 6 × 10
#>   system_id  method pes_calls tot_time success termination_status
#>   <fct>      <chr>      <int>    <dbl> <chr>   <chr>             
#> 1 0_doublets cg_no         75     333. True    GOOD              
#> 2 0_singlets cg_no        154     583. True    GOOD              
#> 3 1_doublets cg_no        389    1983. True    GOOD              
#> 4 1_singlets cg_no        929    3322. True    GOOD              
#> 5 2_doublets cg_no        244    1405. True    GOOD              
#> 6 2_singlets cg_no        269    1094. True    GOOD              
#> # ℹ 4 more variables: rmsd_init_saddle <dbl>, barrier <dbl>, mol_id <int>,
#> #   spin <chr>
```

The columns are:

- `system_id` – identifier combining molecule index and spin state
- `method` – one of `cg_no`, `cg_yes`, `lbfgs_no`, `lbfgs_yes`
  (conjugate-gradient or L-BFGS optimizer, with or without rotation
  removal)
- `pes_calls` – number of potential energy surface evaluations (count)
- `tot_time` – wall-clock time in seconds (positive continuous)
- `success` – logical success flag derived from `termination_status`
- `mol_id` – molecule index (grouping variable)
- `spin` – spin state (doublets or singlets)

``` r
bench$method <- factor(
  bench$method,
  levels = c("cg_no", "cg_yes", "lbfgs_no", "lbfgs_yes")
)

table(bench$method)
#> 
#>     cg_no    cg_yes  lbfgs_no lbfgs_yes 
#>       500       500       500       500
```

The reference level is `cg_no` (conjugate gradient without rotation
removal), against which all other methods are compared.

## Validate the data

``` r
bc_validate(
  bench,
  count_col  = "pes_calls",
  method_col = "method",
  system_col = "system_id"
)
```

## Simple model with bc_fit()

For a first pass, you can use
[`bc_fit()`](https://haozeke.github.io/bayescomp/reference/bc_fit.md)
with the count response:

``` r
fit_simple <- bc_fit(
  bench,
  response    = "pes_calls",
  method_col  = "method",
  system_col  = "system_id",
  model_shape = TRUE,
  file        = "models/idrot_simple"
)

bc_summarize_effects(fit_simple)
```

This gives you percentage change estimates for each method relative to
`cg_no`. However, the four methods form a 2x2 factorial design
(optimizer x rotation removal), and
[`bc_fit()`](https://haozeke.github.io/bayescomp/reference/bc_fit.md)
treats them as four independent levels. To test the interaction between
optimizer choice and rotation removal, you need
[`bc_fit_design()`](https://haozeke.github.io/bayescomp/reference/bc_fit_design.md).

## Factorial design with bc_fit_design()

First, create the factorial columns from the method labels:

``` r
bench <- bench %>%
  mutate(
    optimizer = factor(
      ifelse(grepl("^cg", method), "CG", "LBFGS"),
      levels = c("CG", "LBFGS")
    ),
    rotation_removal = factor(
      ifelse(grepl("_yes$", method), "yes", "no"),
      levels = c("no", "yes")
    )
  )
```

Now specify the interaction formula using
[`brms::bf()`](https://paulbuerkner.com/brms/reference/brmsformula.html):

``` r
library(brms)

design_formula <- bf(
  pes_calls ~ optimizer * rotation_removal + (1 | system_id)
)

fit_design <- bc_fit_design(
  bench,
  formula = design_formula,
  family  = negbinomial(link = "log"),
  file    = "models/idrot_design"
)
```

The interaction term `optimizer:rotation_removal` tells us whether the
benefit of rotation removal depends on which optimizer you use (or vice
versa).

``` r
bc_summarize_effects(fit_design)
```

## Nested random effects

The dimer data has a hierarchical grouping structure: each molecule
(`mol_id`) is tested in two spin states (`spin`), creating the
`system_id = mol_id:spin` compound key. You can model this explicitly:

``` r
nested_formula <- bf(
  pes_calls ~ optimizer * rotation_removal + (1 | mol_id) + (1 | mol_id:spin)
)

fit_nested <- bc_fit_design(
  bench,
  formula = nested_formula,
  family  = negbinomial(link = "log"),
  file    = "models/idrot_nested"
)
```

This partitions variance into molecule-level and spin-state-level
components. Use
[`bc_loo_compare()`](https://haozeke.github.io/bayescomp/reference/bc_loo_compare.md)
to check whether the nested structure improves prediction (see the
model-selection vignette).

## Fitting a suite of models

When your data includes count, time, and success columns,
[`bc_fit_suite()`](https://haozeke.github.io/bayescomp/reference/bc_fit_suite.md)
fits a separate model for each, using the appropriate family
automatically:

- Negative binomial for `pes_calls` (counts)
- Gamma for `tot_time` (positive continuous)
- Bernoulli for `success` (binary)

``` r
# Ensure the success column is properly coded
bench$success_bin <- as.integer(bench$success == "True" | bench$success == TRUE)

suite <- bc_fit_suite(
  bench,
  count_col   = "pes_calls",
  time_col    = "tot_time",
  success_col = "success_bin",
  method_col  = "method",
  system_col  = "system_id",
  file_prefix = "models/idrot_suite"
)

names(suite)
```

Expected output:

    [1] "count" "time" "success"

Each element is a `brmsfit` object. You can extract effects from each:

``` r
lapply(suite, bc_summarize_effects)
```

## Pairwise contrasts

With four methods, there are six pairwise comparisons.
[`bc_pairwise_contrasts()`](https://haozeke.github.io/bayescomp/reference/bc_pairwise_contrasts.md)
uses the marginaleffects package to compute all of them from a single
fitted model.

``` r
contrasts <- bc_pairwise_contrasts(suite$count, method_col = "method")
print(contrasts)
```

Expected output (values are illustrative):

    # A tibble: 6 x 5
      contrast             estimate  lower  upper formatted
      <chr>                   <dbl>  <dbl>  <dbl> <chr>
    1 cg_yes - cg_no         -85.2 -142.3  -28.1 -85.20 [-142.30, -28.10]
    2 lbfgs_no - cg_no       -62.4 -118.7   -6.1 -62.40 [-118.70, -6.10]
    3 lbfgs_yes - cg_no     -120.6 -176.9  -64.3 -120.60 [-176.90, -64.30]
    4 lbfgs_no - cg_yes       22.8  -33.5   79.1 22.80 [-33.50, 79.10]
    5 lbfgs_yes - cg_yes     -35.4  -91.7   20.9 -35.40 [-91.70, 20.90]
    6 lbfgs_yes - lbfgs_no   -58.2 -114.5   -1.9 -58.20 [-114.50, -1.90]

Contrasts whose credible intervals exclude zero provide strong evidence
of a difference. Contrasts that span zero are inconclusive at the chosen
credibility level.

## Plotting contrasts

The contrast plot is a horizontal pointrange chart with a vertical
dashed line at zero:

``` r
bc_plot_contrasts(contrasts)
```

## When to use bc_fit() vs bc_fit_design()

| Situation                              | Function                                                                            |
|----------------------------------------|-------------------------------------------------------------------------------------|
| Two methods, simple comparison         | [`bc_fit()`](https://haozeke.github.io/bayescomp/reference/bc_fit.md)               |
| Two methods with spline covariate      | [`bc_fit()`](https://haozeke.github.io/bayescomp/reference/bc_fit.md)               |
| Three or more methods, no factorial    | [`bc_fit()`](https://haozeke.github.io/bayescomp/reference/bc_fit.md)               |
| Factorial design (optimizer x setting) | [`bc_fit_design()`](https://haozeke.github.io/bayescomp/reference/bc_fit_design.md) |
| Custom random effects structure        | [`bc_fit_design()`](https://haozeke.github.io/bayescomp/reference/bc_fit_design.md) |
| Interaction terms                      | [`bc_fit_design()`](https://haozeke.github.io/bayescomp/reference/bc_fit_design.md) |

[`bc_fit()`](https://haozeke.github.io/bayescomp/reference/bc_fit.md)
constructs the formula for you from column names.
[`bc_fit_design()`](https://haozeke.github.io/bayescomp/reference/bc_fit_design.md)
gives you full control over the brms formula while still providing
bayescomp defaults for priors, diagnostics, and backends.

## Summary

Key bayescomp functions demonstrated in this vignette:

- [`bc_read_benchmark()`](https://haozeke.github.io/bayescomp/reference/bc_read_benchmark.md)
  with `format = "long"` for pre-pivoted data
- [`bc_validate()`](https://haozeke.github.io/bayescomp/reference/bc_validate.md)
  to check data structure before fitting
- [`bc_fit_design()`](https://haozeke.github.io/bayescomp/reference/bc_fit_design.md)
  with
  [`brms::bf()`](https://paulbuerkner.com/brms/reference/brmsformula.html)
  for factorial interaction models
- [`bc_fit_suite()`](https://haozeke.github.io/bayescomp/reference/bc_fit_suite.md)
  to fit count, time, and success models in one call
- [`bc_pairwise_contrasts()`](https://haozeke.github.io/bayescomp/reference/bc_pairwise_contrasts.md)
  for all-pairs method comparisons
- [`bc_plot_contrasts()`](https://haozeke.github.io/bayescomp/reference/bc_plot_contrasts.md)
  for visualizing pairwise differences
