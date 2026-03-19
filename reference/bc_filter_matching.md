# Filter to systems where all methods found the same result

For benchmark comparisons, it is often important to restrict analysis to
systems where all methods converged to the same saddle point (or
minimum). This function filters to systems where a comparison column
(e.g., barrier height or saddle energy) agrees within a tolerance across
all methods.

## Usage

``` r
bc_filter_matching(
  data,
  compare_col,
  method_col = "method",
  system_col = "system_id",
  tol = 0.01,
  require_success = TRUE
)
```

## Arguments

- data:

  Long-format benchmark data.

- compare_col:

  Column to compare across methods (e.g., `"barrier"` or
  `"saddle_energy"`).

- method_col:

  Name of the method column (default `"method"`).

- system_col:

  Name of the system column (default `"system_id"`).

- tol:

  Tolerance for agreement (default 0.01). Systems where the range of
  `compare_col` across methods exceeds `tol` are removed.

- require_success:

  Logical. Also filter to systems where all methods succeeded? (default
  `TRUE`). Requires a `success` column.

## Value

Filtered data frame with only matching systems.

## Examples

``` r
data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2)
data$barrier <- runif(nrow(data), 0.5, 1.5)
bc_filter_matching(data, compare_col = "barrier", require_success = FALSE)
#> Warning: ! All 10 systems filtered out. No systems have "barrier" agreement within
#>   tol=0.01.
#> ℹ Consider increasing `tol` or checking data quality.
#> # A tibble: 0 × 4
#> # ℹ 4 variables: system_id <fct>, method <fct>, count <dbl>, barrier <dbl>
```
