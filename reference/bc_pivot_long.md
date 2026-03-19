# Pivot wide-format benchmark data to long

Converts wide-format benchmark data (one row per system) to long format
(one row per system-method pair). Method-specific columns are identified
by their suffixes and pivoted into a single `method` column.

## Usage

``` r
bc_pivot_long(
  data,
  method_pattern,
  method_levels = NULL,
  count_col = "count",
  time_col = "time",
  success_col = "success",
  success_value = "GOOD",
  cens_value = NULL
)
```

## Arguments

- data:

  Wide-format data frame from
  [`bc_read_benchmark()`](https://haozeke.github.io/bayescomp/reference/bc_read_benchmark.md).

- method_pattern:

  Regex matching method-specific column suffixes (e.g.,
  `"_(CINEB|OCINEB)$"`).

- method_levels:

  Factor levels for the Method column. First level is the reference
  (control) method.

- count_col:

  Name of the count column after pivoting (default `"count"`).

- time_col:

  Name of the time column after pivoting (default `"time"`). Set to
  `NULL` to skip.

- success_col:

  Name of the success column after pivoting (default `"success"`). Set
  to `NULL` to skip.

- success_value:

  Value in the termination column that indicates success (default
  `"GOOD"`).

- cens_value:

  Value in the termination column that indicates a right-censored
  observation (default `NULL`, no censoring column created). When set
  (e.g., `"BAD_MAX_ITERATIONS"`), creates a binary `censored` column (1
  = censored, 0 = observed) alongside the `success` column.

## Value

A long-format tibble with columns: system_id, method, count, and
optionally time, success, and censored.

## Examples

``` r
if (FALSE) { # \dontrun{
raw <- bc_read_benchmark("bench.csv", format = "wide",
  method_suffixes = c("A", "B"))
long <- bc_pivot_long(raw, method_pattern = "_(A|B)$",
  method_levels = c("A", "B"))
} # }
```
