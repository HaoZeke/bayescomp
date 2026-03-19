# Scatter comparison of two methods (1:1 plot)

Scatter plot of method A cost vs method B cost with a 1:1 identity line.
Points are colored by which method is cheaper.

## Usage

``` r
bc_plot_scatter_comparison(
  data,
  response = "count",
  method_col = "method",
  system_col = "system_id",
  log_scale = TRUE,
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

- log_scale:

  Logical. Use log scale on both axes? (default `TRUE`).

- colors:

  Two-element character vector for (method1 better, method2 better).

## Value

A ggplot object.

## Examples

``` r
data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2)
bc_plot_scatter_comparison(data)
```
