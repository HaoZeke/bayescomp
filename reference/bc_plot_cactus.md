# Cactus plot (cumulative performance profile)

Shows what fraction of test systems each method solves within a given
budget of force evaluations (or time). This is the computational
equivalent of a performance profile from optimization benchmarking.

## Usage

``` r
bc_plot_cactus(
  data,
  response = "count",
  method_col = "method",
  max_budget = NULL,
  colors = NULL,
  log_x = FALSE
)
```

## Arguments

- data:

  Long-format benchmark data with columns for system, method, and
  response.

- response:

  Name of the response column (default `"count"`).

- method_col:

  Name of the method column (default `"method"`).

- max_budget:

  Maximum budget to show on x-axis. If `NULL`, uses the maximum observed
  value.

- colors:

  Named character vector of method colors.

- log_x:

  Logical. Use log scale on x-axis? (default `FALSE`).

## Value

A ggplot object.

## Examples

``` r
data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2)
bc_plot_cactus(data)
```
