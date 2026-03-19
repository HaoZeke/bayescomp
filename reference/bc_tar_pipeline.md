# Create a targets-compatible benchmark analysis pipeline

Returns a list of target objects that implement the full bayescomp
workflow: read data, pivot, fit model, run diagnostics, extract effects,
and generate plots.

## Usage

``` r
bc_tar_pipeline(
  data_path,
  method_suffixes,
  method_levels = method_suffixes,
  method_pattern = NULL,
  response = "count",
  system_col = "System",
  count_col = "Calls",
  time_col = NULL,
  success_col = NULL,
  spline_by_method = NULL,
  model_shape = FALSE,
  output_dir = "figures",
  model_file = "data/models/bayescomp_model",
  ...
)
```

## Arguments

- data_path:

  Path to benchmark CSV file.

- method_suffixes:

  Character vector of method suffixes for wide format.

- method_levels:

  Factor levels for method column.

- method_pattern:

  Regex for pivot_longer.

- response:

  Response variable name after pivoting.

- system_col:

  System column name in raw data.

- count_col:

  Count column prefix in raw data.

- time_col:

  Time column prefix (optional).

- success_col:

  Success/termination column prefix (optional).

- spline_by_method:

  Covariate for method-varying spline (optional).

- model_shape:

  Model dispersion by method?

- output_dir:

  Directory for output figures.

- model_file:

  Cache path for fitted model.

- ...:

  Additional arguments passed to
  [`bc_fit()`](https://haozeke.github.io/bayescomp/reference/bc_fit.md).

## Value

A list of `tar_target` objects, or `NULL` if targets is not available.

## Details

This is designed to be called inside `_targets.R` as:

    library(targets)
    library(bayescomp)
    bc_tar_pipeline("inst/extdata/baker_bench.csv", ...)

## Examples

``` r
if (FALSE) { # \dontrun{
library(targets)
bc_tar_pipeline("data/bench.csv",
  method_suffixes = c("A", "B"), response = "count")
} # }
```
