# Getting Started with bayescomp

## What you will build

By the end of this tutorial you will have:

1.  Read a benchmark CSV into R
2.  Fitted a Bayesian hierarchical model comparing two methods
3.  Extracted a publication-ready effect estimate with credible
    intervals
4.  Plotted the results

The whole analysis takes 15 lines of R code. You do not need to know
brms, Stan, or Bayesian statistics to follow along.

## Prerequisites

Install bayescomp and make sure cmdstanr is configured (bayescomp uses
it as the Stan backend):

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

## Step 1 – Read the data

The example data ships with the package. It compares two NEB algorithms
(CI-NEB and OCI-NEB) on 24 transition-state search problems. Each row is
one system; columns like `Calls_CINEB` and `Calls_MMF` hold the force
evaluation counts.

Read it. The columns use suffixes `_CINEB` and `_MMF` (the internal
label for OCI-NEB).

``` r
path <- system.file("extdata", "baker_bench.csv", package = "bayescomp")

bench_raw <- bc_read_benchmark(
  path,
  format         = "wide",
  method_suffixes = c("CINEB", "MMF"),
  system_col     = "System",
  count_col      = "Calls",
  time_col       = "Time",
  success_col    = "Term"
)

dim(bench_raw)
#> [1] 24 27
names(bench_raw)
#>  [1] "System"                "Reaction"              "Formula"              
#>  [4] "N_Atoms"               "Total_Mass"            "E_Diff"               
#>  [7] "Barrier_Diff"          "RMSD_Saddle"           "Ratio_Calls"          
#> [10] "Ratio_Time"            "RMSD_Init_Final_CINEB" "RMSD_Init_Final_MMF"  
#> [13] "Barrier_CINEB"         "Force_CINEB"           "Path_Len_CINEB"       
#> [16] "Calls_CINEB"           "Time_CINEB"            "Term_CINEB"           
#> [19] "Force_Init_CINEB"      "Force_Final_CINEB"     "Barrier_MMF"          
#> [22] "Force_MMF"             "Calls_MMF"             "Time_MMF"             
#> [25] "Term_MMF"              "Force_Init_MMF"        "Force_Final_MMF"
```

[`bc_read_benchmark()`](https://haozeke.github.io/bayescomp/reference/bc_read_benchmark.md)
reads the CSV, converts the system column to a factor, and attaches
metadata attributes that downstream functions use automatically.

## Step 2 – Pivot to long format

Most statistical models expect one observation per row.
[`bc_pivot_long()`](https://haozeke.github.io/bayescomp/reference/bc_pivot_long.md)
reshapes the wide data so that each system-method pair becomes its own
row.

``` r
bench_long <- bc_pivot_long(
  bench_raw,
  method_pattern = "_(CINEB|MMF)$",
  method_levels  = c("CINEB", "MMF"),
  count_col      = "count",
  time_col       = "time",
  success_col    = "success",
  success_value  = "GOOD"
)

head(bench_long)
#> # A tibble: 6 × 21
#>   system_id Reaction            Formula N_Atoms Total_Mass   E_Diff Barrier_Diff
#>   <fct>     <chr>               <chr>     <int>      <dbl>    <dbl>        <dbl>
#> 1 01_hcn    bold('01:')~HCN*'-… CHN           3       27.0  3.00e-6  -0.00000900
#> 2 01_hcn    bold('01:')~HCN*'-… CHN           3       27.0  3.00e-6  -0.00000900
#> 3 02_hcch   bold('02:')~HCCH*'… C2H2          4       26.0 -5.84e-4  -0.000595  
#> 4 02_hcch   bold('02:')~HCCH*'… C2H2          4       26.0 -5.84e-4  -0.000595  
#> 5 03_h2co   bold('03:')~H[2]*C… CH2O          4       30.0 -2.70e-3  -0.00271   
#> 6 03_h2co   bold('03:')~H[2]*C… CH2O          4       30.0 -2.70e-3  -0.00271   
#> # ℹ 14 more variables: RMSD_Saddle <dbl>, Ratio_Calls <dbl>, Ratio_Time <dbl>,
#> #   method <fct>, RMSD_Init_Final <dbl>, Barrier <dbl>, Force <dbl>,
#> #   Path_Len <dbl>, count <int>, time <dbl>, term_reason <chr>,
#> #   Force_Init <dbl>, Force_Final <dbl>, success <lgl>
```

The `method_levels` argument controls factor ordering. The first level
(`"CINEB"`) becomes the reference method in the model, so all treatment
effects are reported relative to CI-NEB.

You can inspect the structure to make sure it looks right:

``` r
str(bench_long[, c("system_id", "method", "count", "time", "success")])
#> tibble [48 × 5] (S3: tbl_df/tbl/data.frame)
#>  $ system_id: Factor w/ 24 levels "01_hcn","02_hcch",..: 1 1 2 2 3 3 14 14 4 4 ...
#>  $ method   : Factor w/ 2 levels "CINEB","MMF": 1 2 1 2 1 2 1 2 1 2 ...
#>  $ count    : int [1:48] 202 177 546 300 882 374 298 135 330 228 ...
#>  $ time     : num [1:48] 6.06 5.66 11.13 8.23 16.45 ...
#>  $ success  : logi [1:48] TRUE TRUE TRUE TRUE TRUE TRUE ...
```

Expected output (abbreviated):

    tibble [48 x ...] (S3: tbl_df/tbl/data.frame)
     $ system_id: Factor w/ 24 levels ...
     $ method   : Factor w/ 2 levels "CINEB","MMF": 1 2 1 2 ...
     $ count    : int  202 177 546 300 882 374 ...
     $ time     : num  6.06 5.66 11.13 8.23 ...
     $ success  : logi  TRUE TRUE TRUE TRUE ...

## Step 3 – Fit the model

[`bc_fit()`](https://haozeke.github.io/bayescomp/reference/bc_fit.md)
selects the response family automatically (negative binomial for integer
counts, Gamma for positive continuous times, Bernoulli for binary
success). It sets weakly informative priors and runs four MCMC chains
via cmdstanr.

The model formula is:

    count ~ method + (1 | system_id)

This is a generalized linear mixed model with a fixed effect for method
and a random intercept per test system, accounting for the fact that
some reactions are inherently harder than others.

``` r
fit_count <- bc_fit(
  bench_long,
  response  = "count",
  model_shape = TRUE,
  file      = "models/baker_count"
)
```

Setting `model_shape = TRUE` adds a shape submodel (`shape ~ method`) so
that the dispersion parameter can differ between CI-NEB and OCI-NEB.
This is important because one method may produce more variable call
counts than the other.

The `file` argument caches the compiled and fitted model to disk, so
subsequent runs load instantly.

**Note:** Model fitting takes 2-5 minutes depending on your hardware.
The code block above uses `eval = FALSE` because MCMC sampling is too
slow for automated vignette builds.

When fitting completes, bayescomp automatically runs convergence
diagnostics and prints a summary:

    v All convergence diagnostics passed (Rhat <= 1.01, ESS >= 400).
    i NB shape (reference): 1.3 (median on response scale)
    i NB shape (MMF): 2.1 [1.0, 4.5]

The low shape values (well below 50) confirm substantial overdispersion,
validating the choice of negative binomial over Poisson.

## Step 4 – Summarize effects

[`bc_summarize_effects()`](https://haozeke.github.io/bayescomp/reference/bc_summarize_effects.md)
extracts the posterior distribution of the method effect and converts it
to interpretable quantities: a multiplicative factor and a percentage
change on the response scale.

``` r
effects <- bc_summarize_effects(fit_count)
print(effects)
```

Expected output:

    # A tibble: 3 x 5
      effect_type                      median  lower  upper formatted
      <chr>                             <dbl>  <dbl>  <dbl> <chr>
    1 Expected Response (Baseline)     551.   331.   917.   551.23 [330.65, 917.42]
    2 Multiplicative Factor (MMF)        0.54   0.45   0.63 0.54 [0.45, 0.63]
    3 Percentage Change (MMF)          -46.4  -54.6  -36.7  -46.41 [-54.62, -36.73]

The key result: OCI-NEB uses 46.4% fewer force/energy evaluations than
CI-NEB, with a 95% credible interval of \[-54.6%, -36.7%\]. Because the
entire interval is negative, there is strong evidence that OCI-NEB is
more efficient.

For a publication-ready table:

``` r
bc_effect_table(fit_count)
```

    # A tibble: 3 x 3
      Effect                           Median  `95% CrI`
      <chr>                            <chr>   <chr>
    1 Expected Response (Baseline)     551.23  [330.65, 917.42]
    2 Multiplicative Factor (MMF)      0.54    [0.45, 0.63]
    3 Percentage Change (MMF)          -46.4%  [-54.6%, -36.7%]

## Step 5 – Plot conditional effects

[`bc_plot_conditional()`](https://haozeke.github.io/bayescomp/reference/bc_plot_conditional.md)
overlays the model’s predicted response on the raw data, letting you see
how well the model captures the pattern across test systems.

``` r
bc_plot_conditional(
  fit_count,
  effects      = "method",
  data         = bench_long,
  response_col = "count",
  log_y        = TRUE
)
```

The resulting plot shows the posterior mean and 95% credible band for
each method, with the raw per-system counts overlaid as jittered points.
The log scale is appropriate here because the negative binomial model
uses a log link.

## Adding covariates

The Baker data includes `RMSD_Init_Final` (the geometric dissimilarity
between reactant and product), which is known to affect the difficulty
of a NEB calculation. You can include this as a method-varying spline:

``` r
fit_spline <- bc_fit(
  bench_long,
  response         = "count",
  spline_by_method = "RMSD_Init_Final",
  model_shape      = TRUE,
  file             = "models/baker_count_spline"
)
```

This adds `s(RMSD_Init_Final, by = method, k = 3)` to the formula,
letting each method have its own smooth relationship with the covariate.
The conditional effects plot then shows predicted counts as a function
of RMSD, coloured by method.

``` r
bc_plot_conditional(
  fit_spline,
  effects      = "RMSD_Init_Final:method",
  data         = bench_long,
  response_col = "count",
  log_y        = TRUE
)
```

## Using a targets pipeline

For reproducible analyses, bayescomp integrates with the targets
package. Place the following in your `_targets.R` file:

``` r
library(targets)
library(bayescomp)

list(
  bc_tar_pipeline(
    data_path       = "inst/extdata/baker_bench.csv",
    method_suffixes = c("CINEB", "MMF"),
    method_levels   = c("CINEB", "MMF"),
    response        = "count",
    system_col      = "System",
    count_col       = "Calls",
    time_col        = "Time",
    success_col     = "Term",
    model_shape     = FALSE,
    model_file      = "data/models/baker_count"
  )
)
```

Run
[`targets::tar_make()`](https://docs.ropensci.org/targets/reference/tar_make.html)
to execute the pipeline. Subsequent runs skip steps whose inputs have
not changed.

## Summary

The typical bayescomp workflow is:

1.  [`bc_read_benchmark()`](https://haozeke.github.io/bayescomp/reference/bc_read_benchmark.md)
    – load your CSV data
2.  [`bc_pivot_long()`](https://haozeke.github.io/bayescomp/reference/bc_pivot_long.md)
    – reshape from wide to long format
3.  [`bc_fit()`](https://haozeke.github.io/bayescomp/reference/bc_fit.md)
    – fit a Bayesian hierarchical model
4.  [`bc_summarize_effects()`](https://haozeke.github.io/bayescomp/reference/bc_summarize_effects.md)
    or
    [`bc_effect_table()`](https://haozeke.github.io/bayescomp/reference/bc_effect_table.md)
    – extract treatment effects
5.  [`bc_plot_conditional()`](https://haozeke.github.io/bayescomp/reference/bc_plot_conditional.md)
    – visualize the model predictions

For diagnostics, model selection, and multi-method comparisons, see the
companion vignettes:

- [`vignette("neb-case-study")`](https://haozeke.github.io/bayescomp/articles/neb-case-study.md)
  – full NEB analysis with diagnostics
- [`vignette("dimer-case-study")`](https://haozeke.github.io/bayescomp/articles/dimer-case-study.md)
  – multi-method comparison (\>2 methods)
- [`vignette("model-selection")`](https://haozeke.github.io/bayescomp/articles/model-selection.md)
  – family selection and prior sensitivity
