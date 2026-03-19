# Compare models via LOO-CV

Compares two or more fitted models using approximate leave-one-out
cross-validation via
[`loo::loo_compare()`](https://mc-stan.org/loo/reference/loo_compare.html).

## Usage

``` r
bc_loo_compare(..., model_names = NULL)
```

## Arguments

- ...:

  Two or more `brmsfit` objects, or a single named list of brmsfit
  objects.

- model_names:

  Optional character vector of model names. If `NULL`, uses the argument
  names or `"model_1"`, `"model_2"`, etc.

## Value

A tibble with columns: model, elpd_diff, se_diff.

## Examples

``` r
if (FALSE) { # \dontrun{
data <- bc_simulate_benchmark(n_systems = 20)
m1 <- bc_fit(data, response = "count")
m2 <- bc_fit(data, response = "count", model_shape = TRUE)
bc_loo_compare(m1, m2, model_names = c("fixed_shape", "varying_shape"))
} # }
```
