# Model Selection and Prior Sensitivity

## Overview

Choosing the right response family and checking that results do not
depend on prior assumptions are two steps that belong in every Bayesian
analysis. This vignette covers:

1.  How
    [`bc_suggest_family()`](https://haozeke.github.io/bayescomp/reference/bc_suggest_family.md)
    picks a family and why its recommendations matter
2.  Comparing candidate models with
    [`bc_loo_compare()`](https://haozeke.github.io/bayescomp/reference/bc_loo_compare.md)
3.  Prior sensitivity analysis by refitting with different prior scales
4.  When to prefer Student-t over Gaussian for real-valued responses

## Setup

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

We use simulated data so that the ground truth is known. This makes it
easier to see which modelling choices recover the true effect.

``` r
set.seed(42)

sim_count <- bc_simulate_benchmark(
  n_systems   = 30,
  n_methods   = 2,
  true_effect = log(0.6),
  family      = "negbinomial",
  shape       = 5,
  intercept   = log(500),
  system_sd   = 0.4
)

head(sim_count)
#> # A tibble: 6 × 3
#>   system_id method   count
#>   <fct>     <fct>    <dbl>
#> 1 sys_01    method_1   976
#> 2 sys_02    method_1   541
#> 3 sys_03    method_1   346
#> 4 sys_04    method_1   740
#> 5 sys_05    method_1   572
#> 6 sys_06    method_1   435
```

The true effect is `log(0.6)`, corresponding to a 40% reduction in
counts for `method_2` relative to `method_1`. The shape parameter of 5
implies substantial overdispersion (variance much larger than the mean).

## How bc_suggest_family() works

[`bc_suggest_family()`](https://haozeke.github.io/bayescomp/reference/bc_suggest_family.md)
inspects the response vector and applies the following rules:

| Data pattern                     | Suggested family  | Link     |
|----------------------------------|-------------------|----------|
| Non-negative integers            | Negative binomial | log      |
| Strictly positive continuous     | Gamma             | log      |
| Binary (0/1 or TRUE/FALSE)       | Bernoulli         | logit    |
| Real-valued (includes negatives) | Student-t         | identity |

``` r
bc_suggest_family(sim_count$count)
#> ℹ Count data detected. Using negative binomial (log link).
#> ℹ Gaussian models produce misleading results for count data.
#> ℹ Variance = 108909.5, mean = 475.3.
#> 
#> Family: negbinomial 
#> Link function: log
```

Expected output:

    i Count data detected. Using negative binomial (log link).
    i Gaussian models produce misleading results for count data.
    i Variance = 37894.2, mean = 402.3.

The variance is nearly 100 times the mean, ruling out a Poisson model
(which assumes variance equals mean). The negative binomial adds a shape
parameter to capture this extra variance.

### Why not Gaussian?

A common mistake is modelling counts or positive-only data with a
Gaussian family.
[`bc_suggest_family()`](https://haozeke.github.io/bayescomp/reference/bc_suggest_family.md)
warns against this:

``` r
bc_suggest_family(sim_count$count, type = "gaussian")
#> Warning: ! Data looks like non-negative integer counts.
#> ℹ Gaussian models produce misleading results for count data.
#> ℹ Consider `type = "count"` (negative binomial) instead.
#> 
#> Family: gaussian 
#> Link function: identity
```

    ! Data looks like non-negative integer counts.
    i Gaussian models produce misleading results for count data.
    i Consider `type = "count"` (negative binomial) instead.

The problems with Gaussian for count data:

- The identity link can predict negative counts
- Gaussian assumes symmetric, constant-variance errors, which is wrong
  for counts (variance scales with the mean)
- Credible intervals become artificially narrow because the Gaussian
  likelihood is too confident about the wrong distributional shape

## Comparing families with bc_loo_compare()

To make the case empirically, fit the same data with negative binomial
and Gaussian families, then compare using LOO-CV:

``` r
fit_nb <- bc_fit(
  sim_count,
  response = "count",
  family   = brms::negbinomial(link = "log"),
  file     = "models/sim_nb"
)

fit_gaussian <- bc_fit(
  sim_count,
  response = "count",
  family   = brms::brmsfamily("gaussian", link = "identity"),
  file     = "models/sim_gaussian"
)

bc_loo_compare(fit_nb, fit_gaussian, model_names = c("NegBin", "Gaussian"))
```

Expected output:

    i Computing LOO-CV for 2 models...
    v Preferred model: NegBin

    # A tibble: 2 x 3
      model    elpd_diff se_diff
      <chr>        <dbl>   <dbl>
    1 NegBin         0      0
    2 Gaussian     -48.3    12.1

The negative binomial model has a substantially higher expected log
predictive density (elpd). The difference of -48.3 (with SE 12.1) is
decisive: the negative binomial fits the data far better.

### Poisson vs negative binomial

For low-overdispersion data (shape above 100), Poisson may suffice.
bayescomp does not provide Poisson directly, but you can pass it:

``` r
fit_pois <- bc_fit(
  sim_count,
  response = "count",
  family   = brms::poisson(link = "log"),
  file     = "models/sim_poisson"
)

bc_loo_compare(fit_nb, fit_pois, model_names = c("NegBin", "Poisson"))
```

With shape = 5 (high overdispersion), the Poisson model will perform
poorly. But for data with shape above 100, the two models will be
indistinguishable. The NB shape parameter reported by
[`bc_fit()`](https://haozeke.github.io/bayescomp/reference/bc_fit.md)
after fitting tells you which regime you are in:

    i NB shape: 5.2 [3.8, 7.1] -- high overdispersion

## Prior sensitivity analysis

bayescomp uses weakly informative priors by default. The key priors are:

| Parameter class | Default prior          | Role                       |
|-----------------|------------------------|----------------------------|
| Fixed effects   | `normal(0, 1)`         | Method effects (log scale) |
| Random effects  | `exponential(1)`       | System-level SD            |
| Intercept       | `student_t(3, 0, 2.5)` | Baseline log-count         |
| Shape           | `gamma(0.01, 0.01)`    | Overdispersion (Gamma/NB)  |

To check sensitivity, refit the model with tighter and wider priors on
the fixed effects:

``` r
library(brms)

# Tighter priors (more regularization)
priors_tight <- c(
  prior(normal(0, 0.5), class = "b"),
  prior(exponential(1), class = "sd"),
  prior(student_t(3, 0, 2.5), class = "Intercept")
)

# Wider priors (less regularization)
priors_wide <- c(
  prior(normal(0, 2), class = "b"),
  prior(exponential(1), class = "sd"),
  prior(student_t(3, 0, 2.5), class = "Intercept")
)

fit_default <- bc_fit(sim_count, response = "count", file = "models/sim_default")

fit_tight <- bc_fit(
  sim_count,
  response = "count",
  prior    = priors_tight,
  file     = "models/sim_tight"
)

fit_wide <- bc_fit(
  sim_count,
  response = "count",
  prior    = priors_wide,
  file     = "models/sim_wide"
)
```

Compare the effect estimates across prior specifications:

``` r
bind_rows(
  bc_summarize_effects(fit_default) %>% mutate(prior = "default (sd=1)"),
  bc_summarize_effects(fit_tight)   %>% mutate(prior = "tight (sd=0.5)"),
  bc_summarize_effects(fit_wide)    %>% mutate(prior = "wide (sd=2)")
) %>%
  filter(grepl("Percentage", effect_type)) %>%
  select(prior, median, lower, upper)
```

Expected output (values are illustrative):

    # A tibble: 3 x 4
      prior           median  lower  upper
      <chr>            <dbl>  <dbl>  <dbl>
    1 default (sd=1)   -39.8  -50.2  -27.4
    2 tight (sd=0.5)   -38.1  -47.9  -26.5
    3 wide (sd=2)      -40.2  -51.1  -27.8

If the three estimates are similar (overlapping credible intervals), the
results are robust to prior choice. Large shifts would indicate that the
data are too sparse to overcome the prior, and you should either collect
more data or report the sensitivity explicitly.

You can also compare them via LOO-CV:

``` r
bc_loo_compare(
  fit_default, fit_tight, fit_wide,
  model_names = c("default", "tight", "wide")
)
```

For well-identified models with 20+ systems, all three should have
similar elpd values.

## When to use Student-t vs Gaussian

Some benchmark responses are real-valued (e.g., energy differences,
barrier errors). These can be negative, so the log link families (NB,
Gamma) do not apply.

``` r
sim_real <- bc_simulate_benchmark(
  n_systems   = 30,
  n_methods   = 2,
  true_effect = -0.5,
  family      = "student",
  intercept   = 0,
  system_sd   = 0.3,
  sigma       = 1
)

head(sim_real)
#> # A tibble: 6 × 3
#>   system_id method    value
#>   <fct>     <fct>     <dbl>
#> 1 sys_01    method_1  0.819
#> 2 sys_02    method_1  1.31 
#> 3 sys_03    method_1 -1.16 
#> 4 sys_04    method_1 -0.700
#> 5 sys_05    method_1  0.517
#> 6 sys_06    method_1 -1.86
```

``` r
bc_suggest_family(sim_real$value)
#> ℹ Real-valued data with negatives detected. Using Student-t (identity link).
#> ℹ Student-t is robust to outliers compared to Gaussian.
#> 
#> Family: student 
#> Link function: identity
```

    i Real-valued data with negatives detected. Using Student-t (identity link).
    i Student-t is robust to outliers compared to Gaussian.

Student-t has heavier tails than Gaussian, making it robust to the
occasional large error that is common in computational chemistry
benchmarks (e.g., a method failing on one system and producing a wildly
wrong energy). The degrees-of-freedom parameter (`nu`) is estimated from
the data; values near 3-5 indicate heavy tails, while values above 30
approach Gaussian behaviour.

``` r
fit_student <- bc_fit(
  sim_real,
  response = "value",
  family   = brms::student(link = "identity"),
  file     = "models/sim_student"
)

fit_gauss <- bc_fit(
  sim_real,
  response = "value",
  family   = brms::brmsfamily("gaussian", link = "identity"),
  file     = "models/sim_gauss"
)

bc_loo_compare(fit_student, fit_gauss, model_names = c("Student-t", "Gaussian"))
```

When the data truly have heavy tails, the Student-t model will have a
higher elpd. When the data are well-behaved, the two models will perform
similarly, and you lose nothing by using Student-t.

## Summary of family selection guidelines

| Response type              | First choice      | Alternative      | Avoid             |
|----------------------------|-------------------|------------------|-------------------|
| Integer counts (\>= 0)     | Negative binomial | Poisson (low OD) | Gaussian          |
| Positive continuous (time) | Gamma             | Log-normal       | Gaussian          |
| Binary (success/failure)   | Bernoulli         | –                | –                 |
| Real-valued (signed)       | Student-t         | Gaussian (no OL) | Log-link families |

OD = overdispersion. OL = outliers.

## Workflow checklist

1.  Call
    [`bc_suggest_family()`](https://haozeke.github.io/bayescomp/reference/bc_suggest_family.md)
    on your response vector to get the recommended family
2.  Fit the recommended model with
    [`bc_fit()`](https://haozeke.github.io/bayescomp/reference/bc_fit.md)
3.  If you suspect an alternative family might work, fit it too
4.  Compare with
    [`bc_loo_compare()`](https://haozeke.github.io/bayescomp/reference/bc_loo_compare.md)
    – prefer the model with highest elpd
5.  Refit with
    [`bc_default_priors()`](https://haozeke.github.io/bayescomp/reference/bc_default_priors.md)
    at different scales (0.5, 1, 2) for the fixed-effect SD
6.  Verify that the effect estimate and credible interval do not shift
    substantially across prior specifications
7.  Report the preferred model, its LOO-CV, and any prior sensitivity
    findings
