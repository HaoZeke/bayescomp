# Simulate benchmark comparison data

Generates synthetic benchmark data from a known data-generating process
for power analysis and parameter recovery testing. Produces long-format
data matching bayescomp conventions.

## Usage

``` r
bc_simulate_benchmark(
  n_systems = 20,
  n_methods = 2,
  true_effect = log(0.5),
  family = c("negbinomial", "gamma", "bernoulli", "student"),
  shape = 50,
  intercept = NULL,
  system_sd = 0.3,
  sigma = 1,
  cens_threshold = NULL,
  seed = 42
)
```

## Arguments

- n_systems:

  Number of test systems (default 20).

- n_methods:

  Number of methods (default 2). Methods are named `"method_1"`,
  `"method_2"`, etc. The first method is the reference.

- true_effect:

  True log-scale effect of non-reference methods relative to the
  reference. For negbinomial/Gamma, this is on the log scale (e.g.,
  `log(0.5)` means 50% reduction). For Bernoulli, on the logit scale.
  Scalar (same for all non-reference methods) or vector of length
  `n_methods - 1`.

- family:

  One of `"negbinomial"`, `"gamma"`, `"bernoulli"`, `"student"`.

- shape:

  Shape parameter for negbinomial or Gamma (default 50).

- intercept:

  Intercept on the link scale (default `log(500)` for negbinomial/Gamma,
  `0` for Bernoulli/Student-t).

- system_sd:

  Standard deviation of the random intercept per system (default 0.3 on
  the link scale).

- sigma:

  Residual SD for Student-t family (default 1).

- cens_threshold:

  Right-censoring threshold. If not `NULL`, observations above this
  value are censored and a `censored` column (0/1) is added.

- seed:

  Random seed for reproducibility.

## Value

A tibble with columns: `system_id` (factor), `method` (factor), and the
response column named `count` (negbinomial), `time` (Gamma), `success`
(Bernoulli), or `value` (Student-t). If `cens_threshold` is set, also
includes `censored` (integer 0/1).

## Examples

``` r
data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2)
head(data)
#> # A tibble: 6 × 3
#>   system_id method   count
#>   <fct>     <fct>    <dbl>
#> 1 sys_01    method_1   960
#> 2 sys_02    method_1   363
#> 3 sys_03    method_1   653
#> 4 sys_04    method_1   664
#> 5 sys_05    method_1   489
#> 6 sys_06    method_1   663
str(data)
#> tibble [20 × 3] (S3: tbl_df/tbl/data.frame)
#>  $ system_id: Factor w/ 10 levels "sys_01","sys_02",..: 1 2 3 4 5 6 7 8 9 10 ...
#>  $ method   : Factor w/ 2 levels "method_1","method_2": 1 1 1 1 1 1 1 1 1 1 ...
#>  $ count    : num [1:20] 960 363 653 664 489 663 827 416 801 559 ...
```
