# Fit a suite of models on the same benchmark data

Fits separate models for count, time, and/or success responses on the
same benchmark data. Only fits models for responses that exist in the
data.

## Usage

``` r
bc_fit_suite(
  data,
  count_col = "count",
  time_col = "time",
  success_col = "success",
  file_prefix = NULL,
  ...
)
```

## Arguments

- data:

  Long-format benchmark data.

- count_col:

  Name of count column (default `"count"`). Set to `NULL` to skip.

- time_col:

  Name of time column (default `"time"`). Set to `NULL` to skip.

- success_col:

  Name of success column (default `"success"`). Set to `NULL` to skip.

- file_prefix:

  Prefix for cached model files (optional).

- ...:

  Additional arguments passed to
  [`bc_fit()`](https://haozeke.github.io/bayescomp/reference/bc_fit.md).

## Value

A named list of `brmsfit` objects.

## Examples

``` r
if (FALSE) { # \dontrun{
data <- bc_simulate_benchmark(n_systems = 20)
models <- bc_fit_suite(data, count_col = "count",
  time_col = NULL, success_col = NULL)
} # }
```
