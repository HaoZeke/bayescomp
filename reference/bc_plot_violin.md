# Violin plot for method comparison

Shows the distribution of a response variable by method using violin
plots with overlaid boxplots and jittered raw points.

## Usage

``` r
bc_plot_violin(
  data,
  response = "count",
  method_col = "method",
  colors = NULL,
  log_y = FALSE
)
```

## Arguments

- data:

  Long-format benchmark data.

- response:

  Name of the response column (default `"count"`).

- method_col:

  Name of the method column (default `"method"`).

- colors:

  Named character vector of method colors.

- log_y:

  Logical. Use log scale on y-axis? (default `FALSE`).

## Value

A ggplot object.

## Examples

``` r
data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2)
bc_plot_violin(data)
```
