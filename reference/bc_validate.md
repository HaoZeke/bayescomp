# Validate benchmark data structure

Checks that a long-format benchmark data frame has the required columns
and types for model fitting. Reports informative errors for NA, NaN,
Inf, and other data quality issues.

## Usage

``` r
bc_validate(
  data,
  count_col = "count",
  method_col = "method",
  system_col = "system_id",
  require_time = FALSE,
  require_success = FALSE,
  allow_negative = FALSE
)
```

## Arguments

- data:

  A data frame to validate.

- count_col:

  Name of the count column (default `"count"`).

- method_col:

  Name of the method column (default `"method"`).

- system_col:

  Name of the system column (default `"system_id"`).

- require_time:

  Logical. Require a time column?

- require_success:

  Logical. Require a success column?

- allow_negative:

  Logical. Allow negative values in the response column? Set to `TRUE`
  for real-valued responses (energy errors, etc.). Default `FALSE`.

## Value

Invisibly returns `data`. Errors on invalid structure.

## Examples

``` r
data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2)
bc_validate(data)
```
