# Signed method difference plot

Shows the signed difference between two methods for each system, sorted
by an auxiliary variable (e.g., RMSD). Points are colored by which
method is better. Includes median and percentile reference lines.

## Usage

``` r
bc_plot_method_diff(
  data,
  response = "count",
  method_col = "method",
  system_col = "system_id",
  sort_by = NULL,
  as_ratio = TRUE,
  colors = NULL
)
```

## Arguments

- data:

  Long-format benchmark data.

- response:

  Name of the response column (default `"count"`).

- method_col:

  Name of the method column (default `"method"`).

- system_col:

  Name of the system column (default `"system_id"`).

- sort_by:

  Column to sort systems by (optional). If `NULL`, sorts by the
  difference itself.

- as_ratio:

  Logical. Show ratio instead of raw difference? (default `TRUE`).

- colors:

  Two-element character vector for (method1 better, method2 better).
  Default: teal, coral.

## Value

A ggplot object.

## Examples

``` r
data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2)
bc_plot_method_diff(data)
```
