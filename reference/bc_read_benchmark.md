# Read and validate benchmark data

Reads a CSV file containing benchmark results for two or more
computational methods. Supports wide format (one row per system,
method-specific columns with suffixes) and long format (one row per
system-method observation).

## Usage

``` r
bc_read_benchmark(
  path,
  format = c("wide", "long"),
  method_suffixes = NULL,
  system_col = "System",
  count_col = "Calls",
  time_col = NULL,
  success_col = NULL
)
```

## Arguments

- path:

  Path to CSV file.

- format:

  One of `"wide"` or `"long"`.

- method_suffixes:

  Character vector of method suffixes for wide format (e.g.,
  `c("CINEB", "OCINEB")`). Required when `format = "wide"`.

- system_col:

  Name of the system/test-problem column.

- count_col:

  Name or prefix of count column(s) (e.g., `"Calls"`).

- time_col:

  Name or prefix of time column(s) (optional).

- success_col:

  Name or prefix of success/termination column(s) (optional).

## Value

A tibble. For wide format, columns are standardized but not yet pivoted.

## Examples

``` r
if (FALSE) { # \dontrun{
raw <- bc_read_benchmark("benchmark.csv", format = "wide",
  method_suffixes = c("A", "B"), count_col = "Calls")
} # }
```
