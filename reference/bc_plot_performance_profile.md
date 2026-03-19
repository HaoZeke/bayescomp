# Performance profile (ratio-based)

Shows what fraction of test systems each method solves within a given
ratio of the best method's cost. A standard visualization from
optimization benchmarking (Dolan and More, 2002).

## Usage

``` r
bc_plot_performance_profile(
  data,
  response = "count",
  method_col = "method",
  system_col = "system_id",
  max_ratio = 10,
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

- max_ratio:

  Maximum performance ratio to show (default 10).

- colors:

  Named character vector of method colors.

## Value

A ggplot object.

## Examples

``` r
data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2)
bc_plot_performance_profile(data)
```
